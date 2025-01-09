//
//  MakeComposition.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 14/11/24.
//

import SwiftUI
import AVFoundation

struct MakeComposition: View {
    
    @StateObject var viewModel = CompositionViewModel()
    
    var body: some View {
        VStack{
            if let composition = viewModel.composition{
                VideoPlayerView(composition: $viewModel.composition)
                    .frame(height: 200)
            }
            //            control buttons
            HStack{
                Button {
                    Task{
                        await viewModel.updateComposition()
                    }
                } label: {
                    Text("Update Player")
                }
            }
            
            HStack{
//                audio assets
                VStack{
                    Text("Audio Assets")
                    List{
                        ForEach(viewModel.audioAssets, id: \.id){asset in
                            VStack{
                                HStack{
                                    ZStack{
                                        Image(uiImage: asset.thumbnail)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 40)
                                            .overlay{
                                                Color.black.opacity(0.3)
                                            }
                                    }
                                    Text(asset.name)
                                    
                                }
                                
                                HStack{
                                    Text(viewModel.getTimeInString(time: asset.duration))
                                        .font(.system(size: 12))
                                    
                                    Text("\(viewModel.getTimeInString(time: asset.startTime))-\(viewModel.getTimeInString(time: asset.endTime))")
                                        .font(.system(size: 12))
                                }
                            }
                            .onTapGesture {
                                if let index = viewModel.audioAssets.firstIndex(where: {$0.id == asset.id}){
                                    
                                    viewModel.selectedAudioAssetIndex = index
                                    viewModel.assetDetailAudioSheet = true
                                }
                            }
                        }
                        .onMove(perform: viewModel.moveAudioAssets)
                    }
                }
                
                VStack{
                    Text("Video Assets")
                    List{
                        ForEach(viewModel.videoAssets, id: \.id){asset in
                            VStack{
                                HStack{
                                    ZStack{
                                        Image(uiImage: asset.thumbnail)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 40)
                                            .overlay{
                                                Color.black.opacity(0.3)
                                            }
                                    }
                                    Text(asset.name)
                                }
                                HStack{
                                    Text(viewModel.getTimeInString(time: asset.duration))
                                        .font(.system(size: 12))
                                    
                                    Text("\(viewModel.getTimeInString(time: asset.startTime))-\(viewModel.getTimeInString(time: asset.endTime))")
                                        .font(.system(size: 12))
                                }
                            }
                            .onTapGesture {
                                if let index = viewModel.videoAssets.firstIndex(where: {$0.id == asset.id}){
                                    
                                    viewModel.selectedVideoAssetIndex = index
                                    viewModel.assetDetailVideoSheet = true
                                }
                            }
                        }
                        .onMove(perform: viewModel.moveVideoAssets)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.assetDetailAudioSheet) {
            AssetDetailEditor(viewModel: viewModel, mediaType: .audio)
                .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $viewModel.assetDetailVideoSheet) {
            AssetDetailEditor(viewModel: viewModel, mediaType: .video)
                .presentationDetents([.height(300)])
        }
        
        
    }
}

struct AssetDetailEditor: View {
    
    @ObservedObject var viewModel: CompositionViewModel
    
    @State var lowerValue: Double = 0
    @State var upperValue: Double = 0
    @State var duration: Double = 10
    @State var images: [UIImage] = []
    var mediaType: AVMediaType
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        VStack(spacing: 5){
            if viewModel.audioAssets.count == 0 || viewModel.videoAssets.count == 0{
                Text("assets not loaded")
            }else{
                
                Slider(value: $lowerValue, in: 0...duration, step: 0.01)
                    .padding()
                    .onChange(of: lowerValue) { newValue in
                        if newValue > upperValue {
                            lowerValue = upperValue
                        }
                    }
                
                // Upper bound slider
                Slider(value: $upperValue, in: 0...duration, step: 0.01)
                    .padding()
                    .onChange(of: upperValue) { newValue in
                        if newValue < lowerValue {
                            upperValue = lowerValue
                        }
                    }
                
                Text("\(lowerValue, specifier: "%.2f") - \(upperValue, specifier: "%.2f")")
                    .font(.system(size: 12))
                if images.count != 0{
                    ZStack{
                        HStack(spacing: 0){
                            ForEach(images, id: \.self){image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 30)
                                    .clipped()
                            }
                        }.opacity(0.2)
                        HStack(spacing: 0){
                            ForEach(images, id: \.self){image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 30)
                                    .clipped()
                            }
                        }.mask {
                            
                            Rectangle().frame(width: (320 / duration) * (upperValue - lowerValue))
                            
                                .padding(.leading, (320 / duration) * lowerValue)
                                .padding(.trailing, (320 / duration) * (duration - upperValue))
                        }
                    }
                }
                
                Button {
                    if mediaType == .audio{
                        viewModel.audioAssets[viewModel.selectedAudioAssetIndex].startTime = CMTime(seconds: lowerValue, preferredTimescale: 600)
                        viewModel.audioAssets[viewModel.selectedAudioAssetIndex].endTime = CMTime(seconds: upperValue, preferredTimescale: 600)
                        print("after making changes, count: \(viewModel.audioAssets.count)")
                    }else{
                        viewModel.videoAssets[viewModel.selectedVideoAssetIndex].startTime = CMTime(seconds: lowerValue, preferredTimescale: 600)
                        viewModel.videoAssets[viewModel.selectedVideoAssetIndex].endTime = CMTime(seconds: upperValue, preferredTimescale: 600)
                        print("after making changes, count: \(viewModel.videoAssets.count)")
                    }
                    
                    viewModel.assetDetailAudioSheet = false
                    viewModel.assetDetailVideoSheet = false
                } label: {
                    Text("save asset changes")
                }

            }
        }
        .onAppear {
            
            let asset = mediaType == .audio ? viewModel.audioAssets[viewModel.selectedAudioAssetIndex] : viewModel.videoAssets[viewModel.selectedVideoAssetIndex]
            lowerValue = asset.startTime.seconds
            upperValue = asset.endTime.seconds
            duration = asset.duration.seconds
            if asset.mediaType == .video{
                Task{
                    let images = await viewModel.getAssetEditorImages(asset: asset.asset, duration: asset.duration)
                    self.images = images
                }
            }else{
                self.images = Array(repeating: UIImage(systemName: "headphones.circle.fill")!, count: 8)
            }
        }
    }
}

struct RangeSliderView: View {
    @State private var lowerValue: Double
    @State private var upperValue: Double
    let lowerBound: Double
    let upperBound: Double
    
    init(lowerBound: Double, upperBound: Double, initialLowerValue: Double, initialUpperValue: Double) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        _lowerValue = State(initialValue: initialLowerValue)
        _upperValue = State(initialValue: initialUpperValue)
    }
    
    
    
    var body: some View {
        VStack {
            Text("Selected Range: \(lowerValue, specifier: "%.2f") - \(upperValue, specifier: "%.2f")")
                .padding()
            
            // Lower bound slider
            Slider(value: $lowerValue, in: lowerBound...upperBound, step: 0.01)
                .padding()
                .onChange(of: lowerValue) { newValue in
                    if newValue > upperValue {
                        lowerValue = upperValue
                    }
                }
            
            // Upper bound slider
            Slider(value: $upperValue, in: lowerBound...upperBound, step: 0.01)
                .padding()
                .onChange(of: upperValue) { newValue in
                    if newValue < lowerValue {
                        upperValue = lowerValue
                    }
                }
        }
        .padding()
    }
}










// OLD CODE
struct MakeComposition2: View {
    
    @StateObject var viewModel = CompositionViewModel2()
    
    var body: some View {
        VStack{
            if let composition = viewModel.composition{
                VideoPlayerView(composition: $viewModel.composition)
                    .frame(height: 200)
            }
            //            control buttons
            HStack{
                Button {
                    Task{
                        await viewModel.updateComposition()
                    }
                } label: {
                    Text("Update Player")
                }
            }
            
            HStack{
                //                audio assets
                VStack{
                    Text("Audio Assets")
                    List{
                        ForEach(viewModel.audioAssets, id: \.id){asset in
                            VStack{
                                HStack{
                                    ZStack{
                                        Image(uiImage: asset.thumbnail)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 40)
                                            .overlay{
                                                Color.black.opacity(0.3)
                                            }
                                    }
                                    Text(asset.name)
                                    
                                }
                                
                                HStack{
                                    Text(viewModel.getTimeInString(time: asset.duration))
                                        .font(.system(size: 12))
                                    
                                    Text("\(viewModel.getTimeInString(time: asset.startTime))-\(viewModel.getTimeInString(time: asset.endTime))")
                                        .font(.system(size: 12))
                                }
                            }
                            .onTapGesture {
                                if let index = viewModel.audioAssets.firstIndex(where: {$0.id == asset.id}){
                                    
                                    viewModel.selectedAudioAssetIndex = index
                                    viewModel.assetDetailAudioSheet = true
                                }
                            }
                        }
                        .onMove(perform: viewModel.moveAudioAssets)
                    }
                }
                
                VStack{
                    Text("Video Assets")
                    List{
                        ForEach(viewModel.videoAssets, id: \.id){asset in
                            VStack{
                                HStack{
                                    ZStack{
                                        Image(uiImage: asset.thumbnail)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 40)
                                            .overlay{
                                                Color.black.opacity(0.3)
                                            }
                                    }
                                    Text(asset.name)
                                }
                                HStack{
                                    Text(viewModel.getTimeInString(time: asset.duration))
                                        .font(.system(size: 12))
                                    
                                    Text("\(viewModel.getTimeInString(time: asset.startTime))-\(viewModel.getTimeInString(time: asset.endTime))")
                                        .font(.system(size: 12))
                                }
                            }
                            .onTapGesture {
                                if let index = viewModel.videoAssets.firstIndex(where: {$0.id == asset.id}){
                                    
                                    viewModel.selectedVideoAssetIndex = index
                                    viewModel.assetDetailVideoSheet = true
                                }
                            }
                        }
                        .onMove(perform: viewModel.moveVideoAssets)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.assetDetailAudioSheet) {
            AssetDetailEditor2(viewModel: viewModel, mediaType: .audio)
                .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $viewModel.assetDetailVideoSheet) {
            AssetDetailEditor2(viewModel: viewModel, mediaType: .video)
                .presentationDetents([.height(300)])
        }
        
        
    }
}

struct AssetDetailEditor2: View {
    
    @ObservedObject var viewModel: CompositionViewModel2
    
    @State var lowerValue: Double = 0
    @State var upperValue: Double = 0
    @State var duration: Double = 10
    @State var images: [UIImage] = []
    var mediaType: AVMediaType
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        VStack(spacing: 5){
            if viewModel.audioAssets.count == 0 || viewModel.videoAssets.count == 0{
                Text("assets not loaded")
            }else{
                
                Slider(value: $lowerValue, in: 0...duration, step: 0.01)
                    .padding()
                    .onChange(of: lowerValue) { newValue in
                        if newValue > upperValue {
                            lowerValue = upperValue
                        }
                    }
                
                // Upper bound slider
                Slider(value: $upperValue, in: 0...duration, step: 0.01)
                    .padding()
                    .onChange(of: upperValue) { newValue in
                        if newValue < lowerValue {
                            upperValue = lowerValue
                        }
                    }
                
                Text("\(lowerValue, specifier: "%.2f") - \(upperValue, specifier: "%.2f")")
                    .font(.system(size: 12))
                if images.count != 0{
                    ZStack{
                        HStack(spacing: 0){
                            ForEach(images, id: \.self){image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 30)
                                    .clipped()
                            }
                        }.opacity(0.2)
                        HStack(spacing: 0){
                            ForEach(images, id: \.self){image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 30)
                                    .clipped()
                            }
                        }.mask {
                            
                            Rectangle().frame(width: (320 / duration) * (upperValue - lowerValue))
                            
                                .padding(.leading, (320 / duration) * lowerValue)
                                .padding(.trailing, (320 / duration) * (duration - upperValue))
                        }
                    }
                }
                
                Button {
                    if mediaType == .audio{
                        viewModel.audioAssets[viewModel.selectedAudioAssetIndex].startTime = CMTime(seconds: lowerValue, preferredTimescale: 600)
                        viewModel.audioAssets[viewModel.selectedAudioAssetIndex].endTime = CMTime(seconds: upperValue, preferredTimescale: 600)
                        print("after making changes, count: \(viewModel.audioAssets.count)")
                    }else{
                        viewModel.videoAssets[viewModel.selectedVideoAssetIndex].startTime = CMTime(seconds: lowerValue, preferredTimescale: 600)
                        viewModel.videoAssets[viewModel.selectedVideoAssetIndex].endTime = CMTime(seconds: upperValue, preferredTimescale: 600)
                        print("after making changes, count: \(viewModel.videoAssets.count)")
                    }
                    
                    viewModel.assetDetailAudioSheet = false
                    viewModel.assetDetailVideoSheet = false
                } label: {
                    Text("save asset changes")
                }
                
            }
        }
        .onAppear {
            
            let asset = mediaType == .audio ? viewModel.audioAssets[viewModel.selectedAudioAssetIndex] : viewModel.videoAssets[viewModel.selectedVideoAssetIndex]
            lowerValue = asset.startTime.seconds
            upperValue = asset.endTime.seconds
            duration = asset.duration.seconds
            if asset.mediaType == .video{
                Task{
                    let images = await viewModel.getAssetEditorImages(asset: asset.asset, duration: asset.duration)
                    self.images = images
                }
            }else{
                self.images = Array(repeating: UIImage(systemName: "headphones.circle.fill")!, count: 8)
            }
        }
    }
}

struct RangeSliderView2: View {
    @State private var lowerValue: Double
    @State private var upperValue: Double
    let lowerBound: Double
    let upperBound: Double
    
    init(lowerBound: Double, upperBound: Double, initialLowerValue: Double, initialUpperValue: Double) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        _lowerValue = State(initialValue: initialLowerValue)
        _upperValue = State(initialValue: initialUpperValue)
    }
    
    
    
    var body: some View {
        VStack {
            Text("Selected Range: \(lowerValue, specifier: "%.2f") - \(upperValue, specifier: "%.2f")")
                .padding()
            
            // Lower bound slider
            Slider(value: $lowerValue, in: lowerBound...upperBound, step: 0.01)
                .padding()
                .onChange(of: lowerValue) { newValue in
                    if newValue > upperValue {
                        lowerValue = upperValue
                    }
                }
            
            // Upper bound slider
            Slider(value: $upperValue, in: lowerBound...upperBound, step: 0.01)
                .padding()
                .onChange(of: upperValue) { newValue in
                    if newValue < lowerValue {
                        upperValue = lowerValue
                    }
                }
        }
        .padding()
    }
}
