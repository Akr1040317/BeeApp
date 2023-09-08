//
//  InputView.swift
//  Bee
//
//  Created by Akshat Rastogi on 5/31/23.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            Text(title)
                .foregroundColor(Color(.white))
                .fontWeight(.semibold)
                .font(.footnote)
            
            if(isSecureField){
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.white))  // Change the foreground color to white
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.white))  // Change the foreground color to white
            }
            
            Divider()
        }
    }
}
