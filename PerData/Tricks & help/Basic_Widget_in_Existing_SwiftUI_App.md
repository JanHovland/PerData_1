# Add a Basic Widget to an Existing SwiftUI App

This guide shows how to add a Widget Extension to an existing SwiftUI
app in Xcode and create a simple widget that displays a temperature.

## 1. Add a Widget Extension

1.  Open your existing project in Xcode.
2.  Select **File → New → Target**.
3.  Select **Widget Extension**.
4.  Click **Next**.
5.  Enter:
    -   **Product Name:** `WeatherWidget`
    -   **Include Configuration Intent:** Unchecked
6.  Click **Finish**.

Your project should now contain two targets:

-   Your existing iOS app.
-   `WeatherWidgetExtension`.

## 2. Create the basic widget

Open the generated `WeatherWidget.swift` file and replace its contents
with:

``` swift
import WidgetKit
import SwiftUI

struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperature: Int
}

struct WeatherProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, temperature: 12)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (WeatherEntry) -> Void
    ) {
        completion(WeatherEntry(date: .now, temperature: 12))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<WeatherEntry>) -> Void
    ) {
        let entry = WeatherEntry(
            date: .now,
            temperature: 15
        )

        let timeline = Timeline(
            entries: [entry],
            policy: .after(.now.addingTimeInterval(15 * 60))
        )

        completion(timeline)
    }
}

struct WeatherWidgetEntryView: View {
    var entry: WeatherProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Places")
                .font(.headline)

            Spacer()

            Text("\\(entry.temperature)°")
                .font(.system(size: 38, weight: .bold))

            Text(entry.date, style: .time)
                .font(.caption)
        }
        .padding()
    }
}

struct WeatherWidget: Widget {

    let kind = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WeatherProvider()
        ) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Displays current temperature.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

## 3. Check the Widget Bundle

Make sure your project contains a `WeatherWidgetBundle.swift` file. It
should look like this:

``` swift
import WidgetKit
import SwiftUI

@main
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
    }
}
```

Xcode normally creates this file when you add the Widget Extension. If
the generated bundle already exists, check it rather than creating a
second `@main` entry point.

## 4. Run and add the widget

1.  Select the `WeatherWidgetExtension` scheme in Xcode.
2.  Choose an iPhone simulator.
3.  Press **Run**.
4.  When the app launches, go to the iPhone Home Screen.
5.  Long-press an empty area of the Home Screen.
6.  Choose **Edit** and then **Add Widget** (the wording can vary
    slightly by iOS version).
7.  Search for **Weather**.
8.  Select the widget size and add it.

## 5. Share data between the app and widget

For an existing app such as **Places**, the widget will usually need
access to data saved by the main app. A common approach is:

-   **App Groups** --- enable the same App Group for both the app target
    and the widget extension.
-   **UserDefaults with a shared suite** --- save values in the app and
    read them in the widget using `UserDefaults(suiteName:)`.
-   **WidgetCenter** --- ask WidgetKit to reload the widget timeline
    after the app saves new data.

For example, the app and widget can both use the same suite name:

``` swift
let sharedDefaults = UserDefaults(
    suiteName: "group.com.example.Places"
)
```

Replace `group.com.example.Places` with the App Group identifier
configured in your Apple Developer account and Xcode.

After saving updated data in the app, request a widget refresh:

``` swift
import WidgetKit

WidgetCenter.shared.reloadTimelines(
    ofKind: "WeatherWidget"
)
```

The widget's `kind` must match the value used in its
`StaticConfiguration`.

### Important notes

-   Enable the same App Group capability on both targets.
-   Widgets do not run continuously in the background.
-   iOS controls when timeline refreshes are performed. A timeline
    policy is a request, not a guarantee that the widget will refresh at
    that exact time.
-   Keep shared data small and suitable for `UserDefaults`; use files in
    the shared App Group container for larger data.

## 6. Next step for the Places app

A useful next version would display the actual temperature for the
selected `Place` using weather data already fetched by the Places app.

A straightforward architecture is:

1.  The Places app fetches weather data with WeatherKit.
2.  The app saves the values the widget needs to the shared App Group.
3.  The app calls `WidgetCenter.shared.reloadTimelines(ofKind:)`.
4.  The widget reads the shared values and displays them.

This avoids making the widget independently fetch the same weather data
just to display the temperature.
