#import "RCTInspectorDevServerHelper.h"

#if RCT_DEV

#import <jschelpers/JSCWrapper.h>

#import "RCTDefines.h"
#import "RCTInspectorPackagerConnection.h"

using namespace facebook::react;

static NSString *getDebugServerHost(NSURL *bundleURL)
{
  NSString *host = [bundleURL host];
  if (!host) {
    host = @"localhost";
  }

  NSNumber *port = [bundleURL port];
  if (!port) {
    port = @8081; // Packager default port
  }

  // this is consistent with the Android implementation, where http:// is the
  // hardcoded implicit scheme for the debug server. Note, packagerURL
  // technically looks like it could handle schemes/protocols other than HTTP,
  // so rather than force HTTP, leave it be for now, in case someone is relying
  // on that ability when developing against iOS.
  return [NSString stringWithFormat:@"%@:%@", host, port];
}

static NSURL *getInspectorDeviceUrl(NSURL *bundleURL)
{
  // TODO: t19163919: figure out if there's a good way to get a friendly device
  // name for the end user
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/inspector/device?name=%@",
                                                        getDebugServerHost(bundleURL),
                                                        @""]];
}


@implementation RCTInspectorDevServerHelper

RCT_NOT_IMPLEMENTED(- (instancetype)init)

+ (void)connectForContext:(JSGlobalContextRef)context
            withBundleURL:(NSURL *)bundleURL
{
  if (!isCustomJSCPtr(context)) {
    return;
  }

  NSURL *inspectorURL = getInspectorDeviceUrl(bundleURL);

  // Note, using a static dictionary isn't really the greatest design, but
  // the packager connection does the same thing, so it's at least consistent.
  // This is a static map that holds different inspector clients per the inspectorURL
  static NSMutableDictionary<NSString *, RCTInspectorPackagerConnection *> *socketConnections = nil;
  if (socketConnections == nil) {
    socketConnections = [NSMutableDictionary new];
  }

  NSString *key = [inspectorURL absoluteString];
  RCTInspectorPackagerConnection *connection = socketConnections[key];
  if (!connection) {
    connection = [[RCTInspectorPackagerConnection alloc] initWithURL:inspectorURL];
    socketConnections[key] = connection;
    [connection connect];
  }
}

@end

#endif
