//
//  ContentView.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 10/11/24.
//



/*
 to do:
 create some good ui for sheet where users adjust the assets.      done
 Separate the audio and video assets.                              done
 fix the aspect ratio of video player.
 finish the blog on video player.                                  done
 Clean the code for composition.
 Start blog on the composition.
 */

import SwiftUI
import AVKit

class VideoPreview: Identifiable{
    var image: UIImage
    var name: String
    var url: URL
    var id: UUID
    init(image: UIImage, name: String, url: URL) {
        self.image = image
        self.name = name
        self.url = url
        self.id = UUID()
    }
}

class ContentViewModel: ObservableObject{
    @Published var videos: [VideoPreview] = []
    
    init() {
        getVideos()
    }
    
    private func getVideos(){
        //        var allVideos: [VideoPreview] = []
        let videoNames: [String] = ["video1.mp4", "video2.mp4", "video3.mp4"]
        
        for videoName in videoNames {
            if let url = Bundle.main.url(forResource: videoName, withExtension: nil){
                generateThumbnail(for: url, at: CMTime(value: 60, timescale: 30)) { image in
                    DispatchQueue.main.async{
                        self.videos.append(VideoPreview(image: UIImage(cgImage: image), name: url.lastPathComponent, url: url))
                    }
                }
            }
        }
    }
    
    private func generateThumbnail(for url: URL, at time: CMTime, completion: @escaping (CGImage) -> ()) {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSizeMake(100, 80)
        
        imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
            if let error = error{
                print("\(error.localizedDescription)")
            }
            if let image = image{
                completion(image)
            }
        }
    }
}

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack{
                ForEach(viewModel.videos){preview in
                    NavigationLink {
//                        WithAVViewController(videoURL: preview.url)
                        
                        VideoWithPlayerLayer(viewModel: VideoPlayerLayerViewModel(asset: AVURLAsset(url: preview.url), videoName: preview.url.lastPathComponent))
                    } label: {
                        HStack{
                            Image(uiImage: preview.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                            Text(preview.name)
                        }
                    }
                }
            }
        }
    }
    
    
}

#Preview {
    ContentView()
}
