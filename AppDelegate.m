//
// AppDelegate.m
// File
//
// Created by Anonym on 07.11.25.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	ViewController *vc = [[ViewController alloc] init];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
	self.window.rootViewController = navController;
	[self.window makeKeyAndVisible];

	return YES;
}


@end
