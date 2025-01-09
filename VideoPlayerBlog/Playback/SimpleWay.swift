//
//  SimpleWay.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 11/11/24.
//

import SwiftUI
import AVKit

/*
 some advantages of using AVplayerViewController:
 has easier implementation. it handles all the play, pausing, seeking controls built in. If you want to use then, set showsPlaybackControls to true. Its set to true by default btw. We don't have to worry about the device orientation, or the full screen modes. The control buttons disappears automatically to remove any obstruction from the video view. And it supports picture in picture right out of the box. This should be usable in 80-90% cases where we just want a simple video player without giving it much attention. 
 */

struct VideoPlayerView: UIViewControllerRepresentable {
//    @Binding var player: AVPlayer
    @Binding var composition: AVMutableComposition?
//    @Binding var compUpdated: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        if let comp = composition{
            playerViewController.player = AVPlayer(playerItem: AVPlayerItem(asset: comp))
        }
//        playerViewController.player = AVPlayer(playerItem: AVPlayerItem(asset: composition))
        playerViewController.showsPlaybackControls = true
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if let comp = composition{
            uiViewController.player = AVPlayer(playerItem: AVPlayerItem(asset: comp))
//            compUpdated = false
        }
//        uiViewController.player = player
    }
}

struct WithAVViewController: View {
    
    @State var player: AVPlayer
    
    init(videoURL: URL) {
        self.player = AVPlayer(url: videoURL)
    }
    
    init(asset: AVAsset){
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    }
    
    var body: some View {
        VStack{
            VideoPlayerView2(player: $player)
                .frame(height: 300)
                .onAppear {
                    player.play()
                }
        }
    }
}


struct VideoPlayerView2: UIViewControllerRepresentable {
    @Binding var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = true
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

