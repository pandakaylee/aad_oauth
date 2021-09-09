import 'package:aad_oauth/auth_token_provider.dart';
import 'package:aad_oauth/bloc/aad_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AzureLoginWidget extends StatelessWidget {
  final AuthTokenProvider authTokenProvider;
  final Widget child;
  AzureLoginWidget({
    required this.child,
    required this.authTokenProvider,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authTokenProvider.bloc,
      child: _AzureLoginSubTree(
        child: child,
      ),
    );
  }
}

class _AzureLoginSubTree extends StatelessWidget {
  final Widget child;

  _AzureLoginSubTree({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AadBloc, AadState>(builder: (context, state) {
      // Use an IndexedStack to keep state between transitions
      var index = 0;
      if (state is AadFullFlowState) index = 1;

      return IndexedStack(
        children: [
          child,
          _FullLoginFlowWidget(
            // This will ensure that every time we go to the full-flow state,
            // we're rebuilding the WebView and making sure that it doesn't end
            // up as a white screen (due to redirections already having occured
            // from a previous interaction).
            key: ValueKey(index),
          ),
        ],
        index: index,
      );
    });
  }
}

class _FullLoginFlowWidget extends StatelessWidget {
  _FullLoginFlowWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AadBloc, AadState>(
      builder: (context, state) {
        final bloc = BlocProvider.of<AadBloc>(context);
        return WebView(
          initialUrl: bloc.tokenRepository.authorizationUrl,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (navigation) {
            bloc.add(AadFullFlowUrlLoadedEvent(navigation.url));
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError wre) {
            bloc.add(AadSignInErrorEvent(wre.description));
          },
        );
      },
    );
  }
}
