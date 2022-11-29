import 'package:flutter/material.dart';
import 'package:tweet_ui/tweet_ui.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart';
import 'package:twitter_oauth2_pkce/twitter_oauth2_pkce.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'twitter_api_v2 with tweet_ui',
      theme: ThemeData(useMaterial3: true),
      home: const TweetUi(),
    );
  }
}

class TweetUi extends StatefulWidget {
  const TweetUi({Key? key}) : super(key: key);

  @override
  State<TweetUi> createState() => _TweetUiState();
}

class _TweetUiState extends State<TweetUi> {
  late TwitterOAuth2Client _oauth2Client;

  @override
  void initState() {
    super.initState();

    //! See https://github.com/twitter-dart/twitter-oauth2-pkce
    _oauth2Client = TwitterOAuth2Client(
      clientId: 'CLIENT_ID',
      clientSecret: 'CLIENT_SECRET',
      redirectUri: 'REDIRECT_URI',
      customUriScheme: 'CUSTOM_URI_SCHEME',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FutureBuilder(
            future: _oauth2Client.executeAuthCodeFlowWithPKCE(
              scopes: [
                Scope.tweetRead,
                Scope.usersRead,
              ],
            ),
            builder: (_, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final twitter =
                  TwitterApi(bearerToken: snapshot.data.accessToken);

              return FutureBuilder(
                future: twitter.users.lookupByName(username: 'elonmusk'),
                builder: (_, AsyncSnapshot snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final UserData user = snapshot.data.data;

                  return FutureBuilder(
                    future: twitter.tweets.lookupTweets(
                      userId: user.id,
                      expansions: TweetExpansion.values,
                      userFields: UserField.values,
                      mediaFields: MediaField.values,
                    ),
                    builder: (_, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final TwitterResponse tweets = snapshot.data;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CompactTweetView.fromTweetV2(
                            TweetV2Response.fromJson(
                              tweets.toJson(),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
