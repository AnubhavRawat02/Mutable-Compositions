//
//  VideoWithPlayerLayer.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 11/11/24.
//

import SwiftUI
import UIKit
import AVFoundation

class PlayerView: UIView {
    
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct AVPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
    }
}

class VideoPlayerLayerViewModel: ObservableObject{
    @Published var player: AVPlayer
    @Published var isPlaying: Bool = false
    
    @Published var duration: Double = 0.0
    @Published var currentTime: Double = 0.0
    
    let imageGenerator: AVAssetImageGenerator
    let videoName: String
    
    @Published var snapshotImage: UIImage? = nil
    @Published var volume: CGFloat = 50
    
    @Published var size: CGSize = CGSize(width: 300, height: 300)
    
    init(asset: AVAsset, videoName: String){
        
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        self.videoName = videoName
        self.imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        addPeriodicTimeObserver()
        Task{
            await getDuration()
            if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first, let naturalSize = try? await videoTrack.load(.naturalSize){
                DispatchQueue.main.async{
                    self.size = naturalSize
                }
            }
        }
        
    }
    
    func changeTime(time: Double){
        let currentTime = player.currentTime()
        player.seek(to: CMTime(seconds: currentTime.seconds + time, preferredTimescale: 600))
    }
    
    private func getDuration() async {
        guard let asset = await player.currentItem?.asset, let totalTime = try? await asset.load(.duration)else{
            return
        }
        DispatchQueue.main.async{
            self.duration = totalTime.seconds
        }
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(value: 30, timescale: 30)
        player.addPeriodicTimeObserver(forInterval: interval,
                                                      queue: .main) { [weak self] time in
            guard let self else { return }
            
            self.currentTime = time.seconds
        }
    }
    
    func convertTimeToString(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        return "\(min < 10 ? "0\(min)" : "\(min)"):\(sec < 10 ? "0\(sec)" : "\(sec)")"
    }
    
    func generateThumbnail(at time: CMTime) {
        
        imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
            if let cgImage = image, error == nil {
                DispatchQueue.main.async {
                    self.snapshotImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
    
    func getVideoHeight() -> CGFloat{
        let screenWidth = UIScreen.main.bounds.width
        let videoHeight = (screenWidth * size.height) / size.width
        return videoHeight
    }
    
    func playVideo(){
        self.player.play()
        isPlaying = true
    }
    
    func pauseVideo(){
        self.player.pause()
        isPlaying = false
    }
    
}

struct VideoWithPlayerLayer: View {
    
    @ObservedObject var viewModel: VideoPlayerLayerViewModel
    
    var body: some View {
//        AVPlayerLayerView(player: viewModel.player)
        ZStack{
            VStack(spacing: 20){
                VStack(spacing: 0){
                    ZStack{
                        Rectangle().fill(.orange)
                            .frame(height: 30)
                        Text(viewModel.videoName)
                    }
                    AVPlayerLayerView(player: viewModel.player)
                        .frame(height: viewModel.getVideoHeight())
                }
                HStack(alignment: .bottom){
                    
                    seekAndPlay
                    Spacer()
                    volumeControl
                    
                }
                .padding(.horizontal, 10)
                
            }
            .padding(.bottom, 30)
            VideoSlider(viewModel: viewModel)
        }
        .frame(height: viewModel.getVideoHeight() + 200)
    }
    
    @ViewBuilder
    var seekAndPlay: some View{
        HStack(spacing: 15){
            Button {
                viewModel.changeTime(time: -10)
            } label: {
                HStack(spacing: 0){
                    Image(systemName: "chevron.left.2")
                        .foregroundStyle(.white)
                }
            }
            
            Button {
                viewModel.changeTime(time: -5)
            } label: {
                HStack(spacing: 3){
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }
            }
            
            Button {
                if viewModel.isPlaying{
                    viewModel.pauseVideo()
                }else{
                    viewModel.playVideo()
                }
            } label: {
                Image(systemName: viewModel.isPlaying ? "square.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            
            Button {
                viewModel.changeTime(time: 5)
            } label: {
                HStack(spacing: 3){
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white)
                }
            }
            
            Button {
                viewModel.changeTime(time: 10)
            } label: {
                HStack(spacing: 0){
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(.white)
                }
            }

        }
    }
    
    @ViewBuilder
    var volumeControl: some View{
        HStack{
            VolumeController(volume: $viewModel.volume)
        }
        .onChange(of: viewModel.volume) { oldValue, newValue in
            let newVolume = Float(newValue / 100)
            viewModel.player.volume = newVolume
        }
    }
}

struct VideoSlider: View {
    
    @ObservedObject var viewModel: VideoPlayerLayerViewModel
    
    @State var showSliderThumbnail: Bool = false
    
    func getSnapshotOffset() -> CGFloat{
        let snapshotWidth: CGFloat = 40
        let sliderWidth: CGFloat = 250
        let totalTime = CGFloat(viewModel.duration)
        let currentTime = CGFloat(viewModel.currentTime)
        
        let offset = ((sliderWidth - snapshotWidth) * currentTime) / totalTime
        return offset
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Spacer()
            if showSliderThumbnail{
                if let uiimage = viewModel.snapshotImage{
                    
                    Image(uiImage: uiimage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .padding(3)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius:3))
                        .offset(x: getSnapshotOffset())
                        
                }
            }
            HStack{
                Text(viewModel.convertTimeToString(seconds: viewModel.currentTime))
                
                
                Slider(value: $viewModel.currentTime, in: 0...viewModel.duration) { isEditing in
                    showSliderThumbnail = isEditing
                }.frame(width: 250)
                    .onChange(of: showSliderThumbnail) { oldValue, newValue in
                        
                        if !newValue{
                            viewModel.player.seek(to: CMTime(seconds: viewModel.currentTime, preferredTimescale: 600))
                            viewModel.playVideo()
                        }else{
                            viewModel.pauseVideo()
                        }
                    }
                    .onChange(of: viewModel.currentTime) { oldValue, newValue in
                        if showSliderThumbnail{
                            viewModel.imageGenerator.cancelAllCGImageGeneration()
                            viewModel.generateThumbnail(at: CMTime(seconds: viewModel.currentTime, preferredTimescale: 600))
                        }
                    }
                    .accentColor(.orange)
                Text(viewModel.convertTimeToString(seconds: viewModel.duration))
            }
        }
        .padding(.bottom, 20)
    }
}
