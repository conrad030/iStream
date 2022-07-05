
# Welcome to iStream!

  

This SwiftUI Framework allows you to add Video Call and Chat to your project within a few lines of code. To use this Framework, you'll need an iOS 15 project. Currently, only Azure Communication Services with a AWS Amplify S3 storage is supported by the framework, but in the future other options are planned.

  

## Installation

To use the framework via Cocoapods, add the following line to your Podfile:

```

pod iStream, "~> 0.2.0"

```

  

## Prerequisites

To use the Video Call and Chat feature, you have to create an Azure Communication Services resource. All information you need for the setup can be found [here](https://docs.microsoft.com/en-us/azure/communication-services/quickstarts/create-communication-resource?tabs=windows&pivots=platform-azp).

  

### Video Call

For the Video Call feature, you'll also need an active Azure Notification Hub resource, which will be used to send and receive push notifications. For the ANH resource you'll need an active Apple Developer Program profile. All infos for the ANH resource can be found [here](https://docs.microsoft.com/en-us/azure/notification-hubs/ios-sdk-get-started#create-a-certificate-for-notification-hubs)

_Note: Make sure to use option 2 with a .p8-Certificate, since only token based authentication will work for the push notifications._

  

### Chat

For the Chat feature, you'll need an active AWS subscription, so the cloud storage for files can be configured. To setup Amplify for your app, follow these instructions:

  

1. Navigate in your Xcode project

2. Configure amplify for your project with:

```

amplify init

```

3. Follow the instructions for the initialization

4. Add storage to your project with:

```

amplify add storage

```

5. Follow the instructions

6. After the storage is setup push the changes to the cloud with:

```

amplify push

```

7. Done!

  

## Usage

### Video Call

First, import the framework module inside your \<YourApp\>App.swift:

```

import iStream

```

Declare and initialize the CallingViewModel in your \<YourApp\>App.swift with the following code piece:

```

@StateObject var callingViewModel: CallingViewModel = CallingViewModel(callingModel: AzureCallingModel())

```

Then add the viewmodel as an environment object on your root view:

```

.environmentObject(self.callingViewModel)

```

After the Viewmodel is initialized, you have to setup the Viewmodel with the ``initCallingViewModel(identifier:displayName:token:)`` function. To generate an identifier and a token for the ACS resource, you can use the Azure plattform or implement an own server. Infos about implementing an own server can the found [here](https://docs.microsoft.com/de-de/azure/communication-services/quickstarts/access-tokens?pivots=programming-language-javascript).

After your viewmodel is initialized, you're ready to make some Video Calls. To start a call, use the ``self.callingViewModel.startCall(identifier:)`` function of the CallingViewModel, where ``identifier``should be an existing identifier from your ACS resource. The property ``presentCallView: Bool`` in CallingViewModel is set to ``true`` when a call successfully started. With this info, you can use the CallView view, to display the UI. If you want to add custom buttons in the CallView, you can add them in the initializer. Alternative you can implement own Views to display the UI by using the CallingViewModel instance.

_Note: The CallView should get the viewmodel passed as an environmentObject with ``.environmentObject(self.callingViewModel)``._

  

### Chat

To use the Chat feature, import the framework module in your \<YourApp\>App.swift file:

```

import iStream

```

After that, declare and initialize the ChatViewModel...

```

@StateObject var chatViewModel: ChatViewModel = ChatViewModel(chatModel: AzureChatModel())

```

... and pass it ass an environmentObject on your root view:

```

.environmentObject(self.chatViewModel)

```

To use the Viewmodel, initialize the chat feature with the ``self.chatViewModel.initChatViewModel(identifier:displayName:endpoint:token:)`` function. To generate an identifier and a token for the ACS resource, you can use the Azure plattform or implement an own server. Infos about implementing an own server can the found [here](https://docs.microsoft.com/de-de/azure/communication-services/quickstarts/access-tokens?pivots=programming-language-javascript). The endpoint parameter is the Endpoint from your ACS resource, which can be found under Settings > Keys in your resource infos in Azure portal.

After your viewmodel is setup, you can use the ``self.chatViewModel.startChat(with:partnerDisplayName:)`` function, where ``identifier``should be an existing identifier from your ACS resource. The ``chatIsSetup: Bool`` property is set to ``true`` when the chat view can be displayed. You can use this info to show the ChatView, to display the UI. If you want to add a custom message view, you can add it in the initializer. Alternative you can implement own Views to display the UI by using the ChatViewModel instance.

_Note: The ChatView should get the viewmodel passed as an environmentObject with ``.environmentObject(self.chatViewModel)``._
