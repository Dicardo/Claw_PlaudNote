//
//  SearchBar.swift
//  PlaudNote
//
//  搜索栏组件
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    SearchBar(text: .constant(""), placeholder: "搜索任务...")
}
