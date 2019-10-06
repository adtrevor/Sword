// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "Sword",
  products: [
    .library(name: "Sword", targets: ["Sword"])
  ],
  dependencies: [.package(url: "https://github.com/vapor/nio-websocket-client.git", .revision("d6111b50ac8b200402d7ed5a8d0bc4a237a1899a"))],
  targets: [
    .target(
      name: "Sword",
      dependencies: ["AsyncWebSocketClient"]
    )
  ]
)
