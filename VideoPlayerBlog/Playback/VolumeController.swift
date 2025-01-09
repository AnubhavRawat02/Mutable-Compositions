//
//  VolumeController.swift
//  VideoPlayerBlog
//
//  Created by Anubhav Rawat on 12/11/24.
//

import SwiftUI

struct TriangleShape: Shape{
    var r: CGFloat = 1.5
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.maxX
        let h = rect.maxY
    
        path.move(to: CGPoint(x: r, y: h))
        path.addQuadCurve(to: CGPoint(x: r, y: h - 1.5*r), control: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w - 1.5*r, y: 0.7 * r))
        path.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - r))
        path.addQuadCurve(to: CGPoint(x: w - r, y: h), control: CGPoint(x: w, y: h))
        path.closeSubpath()
        
        return path
    }
}

struct VolumeController: View {
    
    @Binding var volume: CGFloat
    
    var body: some View {
        VStack(spacing: 2){
            
            ZStack{
                TriangleShape()
                    .stroke(.gray.opacity(0.7), lineWidth: 2)
                    .frame(width: 100, height: 40)
                    .presentationCornerRadius(3)
                Rectangle().fill(LinearGradient(colors: [Color("Low"), Color("Medium"), Color("High")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 100, height: 40)
                    .mask {
                        Rectangle().frame(width: volume)
                            .padding(.trailing, 100 - volume)
                    }
                    .mask {
                        TriangleShape()
                            .frame(width: 100, height: 40)
                    }
                    .gesture(DragGesture()
                        .onEnded({ value in
                            var vol = volume + value.translation.width
                            if vol < 0{
                                vol = 0
                            }else if vol > 100{
                                vol = 100
                            }
                            volume = vol
                        })
                    )
                
            }
            Text("\(String(format: "%.2f", volume))%")
                .font(.system(size: 12))
        }
    }
}

