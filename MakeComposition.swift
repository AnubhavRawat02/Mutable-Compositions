//
//  MakeComposition.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 12/11/24.
//

import SwiftUI
import AVFoundation

struct WrapperScreen: View {
    
    let urls: [URL]
    
    init(){
        let assetNames: [String] = ["audio1.mp3", "audio2.mp3", "audio3.mp3", "movie.MOV", "video1.mp4", "video2.mp4", "video3.mp4"]
        
        var urlArray: [URL] = []
        for assetName in assetNames {
            if let url = Bundle.main.url(forResource: assetName, withExtension: nil){
                urlArray.append(url)
            }
        }
        urls = urlArray
    }
    
    var body: some View {
        PickScreen(viewModel: PickScreenViewModel(videoURLS: urls))
    }
}

class PickScreenViewModel: ObservableObject{
    @Published var assets: [PickScreenAsset] = []
    
    init(videoURLS: [URL]){
        for url in videoURLS {
            print(url.lastPathComponent)
            generateThumbnail(for: url, at: CMTime(seconds: 2, preferredTimescale: 600)) { image in
                DispatchQueue.main.async{
                    if let image = image{
                        self.assets.append(PickScreenAsset(url: url, thumbnail: UIImage(cgImage: image)))
                    }else{
                        self.assets.append(PickScreenAsset(url: url, thumbnail: UIImage(systemName: "headphones.circle.fill")!))
                    }
                }
            }
        }
    }
    
    private func generateThumbnail(for url: URL, at time: CMTime, completion: @escaping (CGImage?) -> ()) {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        
        imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
            if let error = error{
                print("\(error.localizedDescription)")
                completion(nil)
            }
            if let image = image{
                completion(image)
            }
        }
    }
    func moveItem(from source: IndexSet, to destination: Int) {
        assets.move(fromOffsets: source, toOffset: destination)
    }
}

struct PickScreen: View {
    
    @ObservedObject var viewModel: PickScreenViewModel
    
    var body: some View {
        NavigationView {
            VStack{
                List {
                    ForEach(viewModel.assets, id: \.id) { item in
//                        NavigationLink {
//                            VideoWithPlayerLayer(viewModel: VideoPlayerLayerViewModel(videoURL: item.url))
//                        } label: {
//
//                        }

                        HStack{
                            ZStack{
                                Image(uiImage: item.thumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                    .overlay{
                                        Color.black.opacity(0.3)
                                    }
                            }
                            Text(item.name)
                            
                            Spacer()
                            HStack(spacing: 0){
                                if item.hasAudioTracks{
                                    Image(systemName: "headphones")
                                }
                                if item.hasVideoTracks{
                                    Image(systemName: "video.fill")
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            
                        }
                        
                    }
                    .onMove(perform: viewModel.moveItem)
                }
            }
            .navigationTitle(Text("Rearrange your assets"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MakeComposition(viewModel: MakeCompositionViewModel(assetList: viewModel.assets))
                    } label: {
                        Text("Create")
                    }

                }
            }
        }
        
    }
}

class MakeCompositionViewModel: ObservableObject{
    
    init(assetList: [PickScreenAsset]){
        
    }
    
}

struct MakeComposition: View {
    
    @ObservedObject var viewModel: MakeCompositionViewModel
    
    var body: some View {
        VStack{
            Text("make composition")
        }
    }
}

class PickScreenAsset: Identifiable, ObservableObject{
    var id: UUID
    var url: URL
    var name: String
    var asset: AVURLAsset
    var thumbnail: UIImage
    @Published var hasVideoTracks: Bool = false
    @Published var hasAudioTracks: Bool = false
    
    init(url: URL, thumbnail: UIImage){
        self.asset = AVURLAsset(url: url)
        self.id = UUID()
        self.name = url.lastPathComponent
        self.url = url
        self.thumbnail = thumbnail
        
        Task{
            if let videoTracks = try? await asset.loadTracks(withMediaType: .video), videoTracks.count > 0{
                print("\(url.lastPathComponent) video tracks: \(videoTracks.count)")
                DispatchQueue.main.async{
                    self.hasVideoTracks = true
                }
            }
            if let audioTracks = try? await asset.loadTracks(withMediaType: .audio), audioTracks.count > 0{
                print("\(url.lastPathComponent) audio tracks: \(audioTracks.count)")
                DispatchQueue.main.async{
                    self.hasAudioTracks = true
                }
            }
        }
        
    }
    
    
}

#Preview {
    WrapperScreen()
}
