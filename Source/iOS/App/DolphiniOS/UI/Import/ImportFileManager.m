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

- (void)importCopiedFileAtUrl:(NSURL*)url presentingViewController:(UIViewController*)presenter {
  // The import picker supplies a private local copy, not the provider's original.
  NSLog(@"[Import] Received local copy from Files");

  void (^showError)(NSString*) = ^(NSString* message) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:message preferredStyle:UIAlertControllerStyleAlert];
    [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [presenter presentViewController:errorAlert animated:true completion:nil];
  };

  NSURL* destinationUrl = [[NSURL fileURLWithPath:[UserFolderUtil getSoftwareFolder] isDirectory:YES] URLByAppendingPathComponent:url.lastPathComponent];
  NSFileManager* fileManager = [NSFileManager defaultManager];

  if ([fileManager fileExistsAtPath:destinationUrl.path]) {
    showError(@"This software has already been imported.");
    [[NSNotificationCenter defaultCenter] postNotificationName:DOLImportFileFinishedNotification object:self userInfo:nil];
    return;
  }

  UIAlertController* progress = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Import") message:@"Adding software to your library…" preferredStyle:UIAlertControllerStyleAlert];
  [presenter presentViewController:progress animated:true completion:^{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      NSError* error = nil;
      BOOL succeeded = [fileManager createDirectoryAtURL:destinationUrl.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:&error];
      if (succeeded) {
        // Move the staged copy to avoid making another multi-gigabyte copy.
        succeeded = [fileManager moveItemAtURL:url toURL:destinationUrl error:&error];
      }

      NSLog(@"[Import] Library transfer finished: %@ (error domain: %@, code: %ld)", succeeded ? @"success" : @"failure", error.domain, (long)error.code);
      dispatch_async(dispatch_get_main_queue(), ^{
        [progress dismissViewControllerAnimated:true completion:^{
          if (succeeded) {
            [[NSNotificationCenter defaultCenter] postNotificationName:DOLImportFileFinishedNotification object:self userInfo:nil];
          } else {
            showError([NSString stringWithFormat:@"The import failed.\n\n%@", error.localizedDescription ?: @"The downloaded file could not be added to the library."]);
          }
        }];
      });
    });
  }];
}

@end
