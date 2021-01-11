![](https://github.com/ChaosCoder/Beekeeper/blob/master/Logo.png)
[![](http://img.shields.io/badge/Swift-5.0-blue.svg)]() [![](http://img.shields.io/badge/iOS-10.0%2B-blue.svg)]() [![](https://img.shields.io/github/license/ChaosCoder/Beekeeper.svg)](LICENSE.md) [![Build Status](https://app.bitrise.io/app/de6c8de2d3e47847/status.svg?token=almCOiEviEDNJOAM2G5WQQ&branch=master)](https://app.bitrise.io/app/de6c8de2d3e47847)

# Beekeeper
An anonymous usage statistics tracking library for iOS using a [differential privacy](https://en.wikipedia.org/wiki/Differential_privacy) approach.

Beekeeper allows you to get insights about your most important KPIs like daily, weekly or monthy active users, funnels and events and much more without sacrifying the users privacy.

## Install

### CocoaPods

```ruby
pod 'Beekeeper'
```

### Swift Package Manager

```swift
.package(url: "https://github.com/ChaosCoder/Shouter.git", from: "0.5.0")
```

## What user data is stored?

An event in the app (*e.g. user tapped a button or opened the app*) is send via Beekeeper to your server.

An event, that is fired in your app, includes the following data:

- `id: String`: Random UUID for the event
- `product: String`: The app the event was fired in
- `timestamp: Date`: The precise timestamp the event was fired
- `name: String`: The name of the event
- `group: String`: The group/category of the event
- `detail: String?`: A detail of the event (optional)
- `value: Double?`: A numeric value of the event (optional)
- `custom: [String]`: Custom data

Additionally, each event carries metadata. This metadata is usually the crucial part for the privacy of the user. Let's have a look at the metadata:
- `previousEvent: String?`: Event (name), that was triggered before this event within the same group
- `previousEventTimestamp: Day?`: Date (day precision), when an event of the same, was triggered last time
- `install: Day`: Date (day precision), when the user installed the app

*Note: There is no user id, no ip address or other identifying information about the user.*

## Privacy preserving anonymous system

Each event is stored in a database with just the information listed above. Each event is isolated from the history, as the only two links to previous events are too unprecise to be chained together. This way, Beekeeper is anonymous and not only pseudonymous. This property is important for preserving the users privacy, as [pseudonymous solutions can potentially be de-anonymized](https://iapp.org/news/a/looking-to-comply-with-gdpr-heres-a-primer-on-anonymization-and-pseudonymization/).

## Powerfull insights

Beekeeper allows to generate important insights about your app. A basic event that can be tracked in an app is the event of opening the app.

Your **daily app sessions** can then be calculated by just counting those events on the given day. The **daily active users** (who could have multiple sessions a day) can be calculated by just counting the events with a `previousEventTimestamp` of a past day. Same goes with *weekly*, *monthly* or other timeframes.

## Acknowledgments

Base icon made by [Eucalyp](https://www.flaticon.com/authors/eucalyp) from [Flaticon](https://www.flaticon.com/) with some custom coloring.
