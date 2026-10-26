# Duofin privacy

Effective 26 October 2026.

Duofin is a free, open-source Jellyfin client maintained by Justinian / Rated Counsel Limited. It has no advertising or tracking SDK and does not send app analytics to the developer.

## Your Jellyfin server

You choose the server to connect to. Duofin sends that server the information needed to sign in and play your media, including authentication requests, a client/device identifier, media requests, playback progress and settings changes. The server operator controls its logs, accounts and retention. Consult that operator's privacy policy. Prefer HTTPS when connecting over the internet.

Saved server details, access tokens, preferences and cached library information are held on your device using the app's local storage and keychain facilities. You can remove a server or sign out in the app. Removing the app removes its app-container data; iOS keychain behaviour is controlled by the operating system.

Optional features, including local-network discovery, casting and network-specific server selection, use the relevant system permissions. You may deny or revoke them in iOS Settings.

## Review demo and support

The separate Duofin review demo contains freely licensed sample media and is intended for app testing. Like a Jellyfin server generally, it processes connections and playback requests and may retain operational logs. It is not connected to a personal media library. Do not upload personal information to it.

If you contact support or open a public GitHub issue, the information you submit is processed to respond. Do not post passwords, tokens or private server addresses in public issues. GitHub and Apple process information under their own policies when you use their services.

## Contact and source

Contact: hello@ratedcounsel.com

Source: https://github.com/juicecultus/Duofin
