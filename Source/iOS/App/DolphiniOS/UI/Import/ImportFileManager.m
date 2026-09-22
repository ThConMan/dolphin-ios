// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ImportFileManager.h"

#import "Swift.h"

#import "LocalizationUtil.h"

@implementation ImportFileManager

+ (ImportFileManager*)shared {
  static ImportFileManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (void)importFileAtUrl:(NSURL*)url presentingViewController:(UIViewController*)presenter {
  // Files already inside our sandbox do not require a security scope.
  BOOL accessingScopedResource = [url startAccessingSecurityScopedResource];
  NSLog(@"[Import] Starting import; security scope acquired: %@", accessingScopedResource ? @"YES" : @"NO");

  void (^finish)(void) = ^{
    if (accessingScopedResource) {
      [url stopAccessingSecurityScopedResource];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:DOLImportFileFinishedNotification object:self userInfo:nil];
  };

  void (^showError)(NSString*) = ^(NSString* message) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:message preferredStyle:UIAlertControllerStyleAlert];
    [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [presenter presentViewController:errorAlert animated:true completion:nil];
  };

  NSURL* destinationUrl = [[NSURL fileURLWithPath:[UserFolderUtil getSoftwareFolder] isDirectory:YES] URLByAppendingPathComponent:url.lastPathComponent];
  NSFileManager* fileManager = [NSFileManager defaultManager];

  if ([fileManager fileExistsAtPath:destinationUrl.path]) {
    finish();
    showError(@"This software has already been imported.");
    return;
  }

  UIAlertController* alert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Import") message:url.lastPathComponent preferredStyle:UIAlertControllerStyleAlert];

  void (^transfer)(BOOL) = ^(BOOL move) {
    // Wait for the choice alert to leave before presenting progress or errors.
    [presenter dismissViewControllerAnimated:true completion:^{
      UIAlertController* progress = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Import") message:@"Importing software. This may take a while for large files or cloud downloads." preferredStyle:UIAlertControllerStyleAlert];
      [presenter presentViewController:progress animated:true completion:^{
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
          NSError* coordinationError = nil;
          __block NSError* operationError = nil;
          __block BOOL succeeded = NO;
          NSFileCoordinator* coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];

          if ([fileManager createDirectoryAtURL:destinationUrl.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:&operationError]) {
            if (move) {
              [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForMoving writingItemAtURL:destinationUrl options:0 error:&coordinationError byAccessor:^(NSURL* source, NSURL* destination) {
                [coordinator itemAtURL:source willMoveToURL:destination];
                succeeded = [fileManager moveItemAtURL:source toURL:destination error:&operationError];
                if (succeeded) {
                  [coordinator itemAtURL:source didMoveToURL:destination];
                }
              }];
            } else {
              [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges writingItemAtURL:destinationUrl options:0 error:&coordinationError byAccessor:^(NSURL* source, NSURL* destination) {
                succeeded = [fileManager copyItemAtURL:source toURL:destination error:&operationError];
              }];
            }
          }

          NSError* error = coordinationError ?: operationError;
          NSLog(@"[Import] %@ finished: %@ (error domain: %@, code: %ld)", move ? @"Move" : @"Copy", succeeded ? @"success" : @"failure", error.domain, (long)error.code);
          dispatch_async(dispatch_get_main_queue(), ^{
            [progress dismissViewControllerAnimated:true completion:^{
              finish();
              if (!succeeded) {
                showError([NSString stringWithFormat:@"The import failed.\n\n%@", error.localizedDescription ?: @"The selected file could not be read. Try downloading it in Files first."]);
              }
            }];
          });
        });
      }];
    }];
  };

  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    transfer(NO);
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Move") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    transfer(YES);
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    finish();
  }]];

  [presenter presentViewController:alert animated:true completion:^{
    NSLog(@"[Import] Import choices presented");
  }];
}

@end
