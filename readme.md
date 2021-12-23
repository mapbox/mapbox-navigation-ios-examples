# Mapbox Navigation SDK Examples

[![CircleCI](https://circleci.com/gh/mapbox/mapbox-navigation-ios-examples.svg?style=svg)](https://circleci.com/gh/mapbox/mapbox-navigation-ios-examples)

A collection of examples showing off the [Mapbox Navigation SDK](https://github.com/mapbox/mapbox-navigation-ios).

![](https://user-images.githubusercontent.com/1496498/88307292-9db6a000-ccc0-11ea-9507-74c2e918dd98.gif)

## Installation

_Installation with CocoaPods_ 

1. `git clone https://github.com/mapbox/mapbox-navigation-ios-examples.git`
1. `cd mapbox-navigation-ios-examples`
1. Go to your [Mapbox account dashboard](https://account.mapbox.com/) and create an access token that has the `DOWNLOADS:READ` scope. **PLEASE NOTE: This is not the same as your production Mapbox API token. Make sure to keep it private and do not insert it into any Info.plist file.** Create a file named `.netrc` in your home directory if it doesn’t already exist, then add the following lines to the end of the file:
   ```
   machine api.mapbox.com 
     login mapbox
     password YOUR_SECRET_MAPBOX_TOKEN
   ```
   where _YOUR_SECRET_MAPBOX_TOKEN_ is your Mapbox API token with the `DOWNLOADS:READ` scope. The login should always be `mapbox`. It should not be your personal username used to create the secret token.
1. Run `pod repo update && pod install` and open the resulting Navigation-Examples.xcworkspace.
1. Sign up or log in to your Mapbox account and grab a [Mapbox access token](https://www.mapbox.com/help/define-access-token/).
1. Enter your Mapbox access token into the value of the `MBXAccessToken` key within the Info.plist file. Alternatively, if you plan to use this project as the basis for any open source application, [read this guide](https://docs.mapbox.com/help/troubleshooting/private-access-token-android-and-ios/#ios) to learn how to best protect your access tokens.
1. Building and run the Navigation-Examples scheme.

## Add an example:

1. Add the example to [`/Examples`](https://github.com/mapbox/navigation-ios-examples/tree/main/Navigation-Examples/Examples).
1. Add the example name to the [`Constants.swift`](https://github.com/mapbox/navigation-ios-examples/blob/main/Navigation-Examples/Constants.swift).
1. Run the app.

## Additional resources

While we are not able to answer support questions in this repository, below are some helpful resources if you're just getting started with the Mapbox Navigation SDK for iOS: 

- [Mapbox Navigation SDK for iOS documentation](https://docs.mapbox.com/ios/navigation/guides/)
- [Mapbox Navigation SDK for iOS examples](https://www.mapbox.com/ios-sdk/navigation/examples/)
- [Build a navigation app for iOS tutorial](https://www.mapbox.com/help/ios-navigation-sdk/)
- [Mapbox help page](https://www.mapbox.com/help/)
- [Mapbox navigation questions on Stack Overflow](http://stackoverflow.com/questions/tagged/mapbox+ios+navigation)
