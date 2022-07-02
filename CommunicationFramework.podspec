Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '15.0'
s.name = "CommunicationFramework"
s.summary = "Integrate Video Call and Chat in your project within a few lines of code."
s.requires_arc = true

s.version = "0.1.0"

s.license = { :type => "MIT", :file => "LICENSE" }

s.author = { "Conrad Felgentreff" => "conrad.felgentreff@web.de" }
s.homepage = "https://github.com/conrad030/CommunicationFramework"
s.source = { :git => "https://github.com/conrad030/CommunicationFramework.git",
             :tag => "#{s.version}" }

s.framework = "SwiftUI"
s.dependency 'AzureCommunicationCalling', '~> 2.0.0'
s.dependency 'AzureCommunicationChat'
s.dependency 'Amplify'
s.dependency 'AmplifyPlugins/AWSS3StoragePlugin'
s.dependency 'AmplifyPlugins/AWSCognitoAuthPlugin'

s.source_files = "CommunicationFramework/**/*.{swift}"

s.resources = "CommunicationFramework/**/*.{png,jpeg,jpg,xcassets,xcdatamodeld}"

s.swift_version = "5.0"

s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end
