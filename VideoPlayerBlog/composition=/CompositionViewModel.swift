//
//  CompositionViewModel.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 15/11/24.
//


/*
 timeline asset: Only has one track. One audio and one video tracks.
 Mutable composition tracks one for audio and one for video. 
 */

import SwiftUI
import AVFoundation
import os

class TimelineAsset: ObservableObject, Identifiable{
    var id: UUID
    var url: URL
//    var track: AVAssetTrackdfas
    var asset: AVURLAsset
    var mediaType: AVMediaType
    var thumbnail: UIImage
    var name: String
    @Published var startTime: CMTime
    @Published var endTime: CMTime
    let duration: CMTime
    init(url: URL, mediaType: AVMediaType, thumbnail: UIImage, track: AVAssetTrack, name: String, duration: CMTime){
        self.id = UUID()
        self.url = url
        self.asset = AVURLAsset(url: url)
//        self.track = track
        self.mediaType = mediaType
        self.thumbnail = thumbnail
        self.name = name
        self.startTime = .zero
        self.endTime = duration
        self.duration = duration
    }
}

class MutableVideoComposition{
    
}

class CompositionViewModel: ObservableObject{
//    @Published var assets: [AssetTrack] = []
    
    @Published var audioAssets: [TimelineAsset] = []
    @Published var videoAssets: [TimelineAsset] = []
    @Published var composition: AVMutableComposition?
    
    @Published var assetDetailVideoSheet: Bool = false
    @Published var assetDetailAudioSheet: Bool = false
    
    @Published var selectedAudioAssetIndex: Int = 0
    @Published var selectedVideoAssetIndex: Int = 0
    
//    generates url array, and gets the audio and video assets using get assets function
    init(){
        let assetNames: [String] = ["audio1.mp3", "audio2.mp3", "audio3.mp3", "movie.MOV", "video1.mp4", "video2.mp4", "video3.mp4"]
        var urlArray: [URL] = []
        for asset in assetNames{
            if let url = Bundle.main.url(forResource: asset, withExtension: nil){
                urlArray.append(url)
            }
        }
        
        Task{
            await getAssets(videoURLS: urlArray)
        }
    }
    
//    uses the url array to generate the assets.
    private func getAssets(videoURLS: [URL]) async {
        
        for url in videoURLS{
            let asset = AVURLAsset(url: url)
            
            guard let videoTracks = try? await asset.loadTracks(withMediaType: .video), let audioTracks = try? await asset.loadTracks(withMediaType: .audio), let duration = try? await asset.load(.duration) else{return}
            
            
            for videoTrack in videoTracks {
                generateThumbnail(for: url, at: CMTime(seconds: 2, preferredTimescale: 600)) { image in
                    DispatchQueue.main.async{
                        print("adding video asset")
                        self.videoAssets.append(TimelineAsset(url: url, mediaType: .video, thumbnail: image, track: videoTrack, name: url.lastPathComponent, duration: duration))
                    }
                    
                }
            }
            
            
            for audioTrack in audioTracks {
                DispatchQueue.main.async{
                    print("adding audio asset")
                    self.audioAssets.append(TimelineAsset(url: url, mediaType: .audio, thumbnail: UIImage(systemName: "headphones.circle.fill")!, track: audioTrack, name: url.lastPathComponent, duration: duration))
                }
                
            }
        }
    }
    
    func createComposition(movieAssets: [AVAsset]) async -> AVMutableComposition {
        let mutableComposition = AVMutableComposition()
//        creating empty tracks
        let audioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
//        time till which we have entered contents in our empty tracks.
        var audioTime: CMTime = .zero
        var videoTime: CMTime = .zero
        
        for movie in movieAssets{
            
            let timeToAdd = max(audioTime, videoTime)
//            add audio contents of the movie to the audioTrack
            if let movieAudioTrack = try? await movie.loadTracks(withMediaType: .audio).first, let trackDuration = try? await movieAudioTrack.load(.timeRange).duration{
                
                let durationOfAudioToBeAdded = CMTimeRange(start: .zero, duration: trackDuration)
                
                try? audioTrack?.insertTimeRange(durationOfAudioToBeAdded, of: movieAudioTrack, at: timeToAdd)
                audioTime = timeToAdd + trackDuration
            }
            
//            add video contents of the movie to the videoTrack
            if let movieVideoTrack = try? await movie.loadTracks(withMediaType: .video).first, let trackDuration = try? await movieVideoTrack.load(.timeRange).duration{
                
                let durationOfVideoToBeAdded = CMTimeRange(start: .zero, duration: trackDuration)
                
                try? videoTrack?.insertTimeRange(durationOfVideoToBeAdded, of: movieVideoTrack, at: timeToAdd)
                
                videoTime = timeToAdd + trackDuration
                
            }
        }
            
        return mutableComposition
    }
    
    func updateComposition() async {
        var audioTime: CMTime = .zero
        var videoTime: CMTime = .zero
        
        let mutableComp = AVMutableComposition()
        let audioTrack = mutableComp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoTrack = mutableComp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        print("number of assets: \(videoAssets.count)  \(audioAssets.count)")
        for asset in audioAssets {
            if let track = try? await asset.asset.loadTracks(withMediaType: .audio).first{
                try? audioTrack?.insertTimeRange(CMTimeRange(start: asset.startTime, end: asset.endTime), of: track, at: audioTime)
                let timeUsed = asset.endTime - asset.startTime
                audioTime = audioTime + timeUsed
                
            }
        }
        
        for asset in videoAssets{
            if let track = try? await asset.asset.loadTracks(withMediaType: .video).first{
                
                try? videoTrack?.insertTimeRange(CMTimeRange(start: asset.startTime, end: asset.endTime), of: track, at: videoTime)
                let timeUsed = asset.endTime - asset.startTime
                videoTime = videoTime + timeUsed
            }
        }
        
        DispatchQueue.main.async{
            self.composition = mutableComp
        }
    }
    
    private func generateThumbnail(for url: URL, at time: CMTime, completion: @escaping (UIImage) -> ()) {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        
        imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
            if let error = error{
                print("\(error.localizedDescription)")
                completion(UIImage(systemName: "headphones.circle.fill")!)
            }
            if let image = image{
                completion(UIImage(cgImage: image))
            }
        }
    }
    
    func moveAudioAssets(from source: IndexSet, to destination: Int){
        audioAssets.move(fromOffsets: source, toOffset: destination)
    }
    
    func moveVideoAssets(from source: IndexSet, to destination: Int){
        videoAssets.move(fromOffsets: source, toOffset: destination)
    }
    
    func getTimeInString(time: CMTime) -> String{
        let totalSeconds = Int(time.seconds)
        let sec = totalSeconds % 60
        let min = totalSeconds / 60
        return "\(min < 10 ? "0\(min)" : "\(min)"):\(sec < 10 ? "0\(sec)" : "\(sec)")"
    }
    
    func getAssetEditorImages(asset: AVAsset, duration: CMTime) async -> [UIImage]{
        
        var images: [UIImage] = []
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        
        let numberOfIntervals = 8
        
        // Calculate the interval
        let interval = CMTimeMultiplyByFloat64(duration, multiplier: 1.0 / Double(numberOfIntervals - 1))
        
        // Generate the time objects
        var times: [CMTime] = []
        for i in 0..<numberOfIntervals {
            let time = CMTimeMultiply(interval, multiplier: Int32(i))
            times.append(time)
        }
        
//        let timeValues = times.map{NSValue(time: $0)}
        
        let dispatchGroup = DispatchGroup()
        for time in times{
            dispatchGroup.enter()
            imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
                do {dispatchGroup.leave()}
                if let image = image{
                    images.append(UIImage(cgImage: image))
                }
            }
        }
        
        await withCheckedContinuation { continuation in
            dispatchGroup.notify(queue: .main){
                continuation.resume()
            }
        }
        
        return images
    }
    
    
    func exportComposition(url: URL) async {
        
        guard let composition = composition, let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else{return}
        
        if FileManager.default.fileExists(atPath: url.path()){
            try? FileManager.default.removeItem(at: url)
        }
        try? await exportSession.export(to: url, as: .mp4)
        
    }
    
}









// OLD CODE
class AssetTrack2: ObservableObject, Identifiable{
    var id: UUID
    var url: URL
    //    var track: AVAssetTrackdfas
    var asset: AVURLAsset
    var mediaType: AVMediaType
    var thumbnail: UIImage
    var name: String
    @Published var startTime: CMTime
    @Published var endTime: CMTime
    let duration: CMTime
    init(url: URL, mediaType: AVMediaType, thumbnail: UIImage, track: AVAssetTrack, name: String, duration: CMTime){
        self.id = UUID()
        self.url = url
        self.asset = AVURLAsset(url: url)
        //        self.track = track
        self.mediaType = mediaType
        self.thumbnail = thumbnail
        self.name = name
        self.startTime = .zero
        self.endTime = duration
        self.duration = duration
    }
}

class CompositionViewModel2: ObservableObject{
    //    @Published var assets: [AssetTrack] = []
    
    @Published var audioAssets: [AssetTrack2] = []
    @Published var videoAssets: [AssetTrack2] = []
    @Published var composition: AVMutableComposition?
    
    @Published var assetDetailVideoSheet: Bool = false
    @Published var assetDetailAudioSheet: Bool = false
    
    @Published var selectedAudioAssetIndex: Int = 0
    @Published var selectedVideoAssetIndex: Int = 0
    
    //    generates url array, and gets the audio and video assets using get assets function
    init(){
        let assetNames: [String] = ["audio1.mp3", "audio2.mp3", "audio3.mp3", "movie.MOV", "video1.mp4", "video2.mp4", "video3.mp4"]
        var urlArray: [URL] = []
        for asset in assetNames{
            if let url = Bundle.main.url(forResource: asset, withExtension: nil){
                urlArray.append(url)
            }
        }
        
        Task{
            await getAssets(videoURLS: urlArray)
        }
    }
    
    //    uses the url array to generate the assets.
    private func getAssets(videoURLS: [URL]) async {
        
        for url in videoURLS{
            let asset = AVURLAsset(url: url)
            
            guard let videoTracks = try? await asset.loadTracks(withMediaType: .video), let audioTracks = try? await asset.loadTracks(withMediaType: .audio), let duration = try? await asset.load(.duration) else{return}
            
            
            for videoTrack in videoTracks {
                generateThumbnail(for: url, at: CMTime(seconds: 2, preferredTimescale: 600)) { image in
                    DispatchQueue.main.async{
                        print("adding video asset")
                        self.videoAssets.append(AssetTrack2(url: url, mediaType: .video, thumbnail: image, track: videoTrack, name: url.lastPathComponent, duration: duration))
                    }
                    
                }
            }
            
            
            for audioTrack in audioTracks {
                DispatchQueue.main.async{
                    print("adding audio asset")
                    self.audioAssets.append(AssetTrack2(url: url, mediaType: .audio, thumbnail: UIImage(systemName: "headphones.circle.fill")!, track: audioTrack, name: url.lastPathComponent, duration: duration))
                }
                
            }
        }
    }
    
    func updateComposition() async {
        var audioTime: CMTime = .zero
        var videoTime: CMTime = .zero
        
        let mutableComp = AVMutableComposition()
        let audioTrack = mutableComp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoTrack = mutableComp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        print("number of assets: \(videoAssets.count)  \(audioAssets.count)")
        for asset in audioAssets {
            if let track = try? await asset.asset.loadTracks(withMediaType: .audio).first{
                try? audioTrack?.insertTimeRange(CMTimeRange(start: asset.startTime, end: asset.endTime), of: track, at: audioTime)
                let timeUsed = asset.endTime - asset.startTime
                audioTime = audioTime + timeUsed
            }
        }
        
        for asset in videoAssets{
            if let track = try? await asset.asset.loadTracks(withMediaType: .video).first{
                try? videoTrack?.insertTimeRange(CMTimeRange(start: asset.startTime, end: asset.endTime), of: track, at: videoTime)
                let timeUsed = asset.endTime - asset.startTime
                videoTime = videoTime + timeUsed
            }
        }
        
        DispatchQueue.main.async{
            self.composition = mutableComp
        }
    }
    
    private func generateThumbnail(for url: URL, at time: CMTime, completion: @escaping (UIImage) -> ()) {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        
        imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
            if let error = error{
                print("\(error.localizedDescription)")
                completion(UIImage(systemName: "headphones.circle.fill")!)
            }
            if let image = image{
                completion(UIImage(cgImage: image))
            }
        }
    }
    
    func moveAudioAssets(from source: IndexSet, to destination: Int){
        audioAssets.move(fromOffsets: source, toOffset: destination)
    }
    
    func moveVideoAssets(from source: IndexSet, to destination: Int){
        videoAssets.move(fromOffsets: source, toOffset: destination)
    }
    
    func getTimeInString(time: CMTime) -> String{
        let totalSeconds = Int(time.seconds)
        let sec = totalSeconds % 60
        let min = totalSeconds / 60
        return "\(min < 10 ? "0\(min)" : "\(min)"):\(sec < 10 ? "0\(sec)" : "\(sec)")"
    }
    
    func getAssetEditorImages(asset: AVAsset, duration: CMTime) async -> [UIImage]{
        
        var images: [UIImage] = []
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        
        let numberOfIntervals = 8
        
        // Calculate the interval
        let interval = CMTimeMultiplyByFloat64(duration, multiplier: 1.0 / Double(numberOfIntervals - 1))
        
        // Generate the time objects
        var times: [CMTime] = []
        for i in 0..<numberOfIntervals {
            let time = CMTimeMultiply(interval, multiplier: Int32(i))
            times.append(time)
        }
        
        //        let timeValues = times.map{NSValue(time: $0)}
        
        let dispatchGroup = DispatchGroup()
        for time in times{
            dispatchGroup.enter()
            imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
                do {dispatchGroup.leave()}
                if let image = image{
                    images.append(UIImage(cgImage: image))
                }
            }
        }
        
        await withCheckedContinuation { continuation in
            dispatchGroup.notify(queue: .main){
                continuation.resume()
            }
        }
        
        return images
    }
    
}
