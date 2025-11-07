//
// ViewController.m
// File
//
// Created by Anonym on 07.11.25.
//

#import "ViewController.h"
#import "Managers/ImageCacheManager.h"
#import <WebKit/WebKit.h>

@interface ViewController ()

@property (strong, nonatomic) UITextField *urlTextField;
@property (strong, nonatomic) UIButton *getImageButton;
@property (strong, nonatomic) UIButton *clearCacheButton;
@property (strong, nonatomic) UIImageView *urlImageView;
@property (strong, nonatomic) UIImageView *cacheImageView;
@property (strong, nonatomic) WKWebView *html5WebView;
@property (strong, nonatomic) UILabel *urlImageLabel;
@property (strong, nonatomic) UILabel *cacheImageLabel;
@property (strong, nonatomic) UILabel *html5ImageLabel;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (strong, nonatomic) NSString *currentImageURL;
@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) ImageCacheManager *cacheManager;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor systemBackgroundColor];
	self.title = @"Image Downloader";
	
	// Setup Cache Manager
	self.cacheManager = [ImageCacheManager sharedManager];
	
	// Setup URL Session
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	self.urlSession = [NSURLSession sessionWithConfiguration:config];
	
	[self setupUI];
	[self setupConstraints];
	[self setupKeyboardHandling];
}

- (void)setupUI {
	// Scroll View
	self.scrollView = [[UIScrollView alloc] init];
	self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
	self.scrollView.showsVerticalScrollIndicator = YES;
	self.scrollView.alwaysBounceVertical = YES;
	[self.view addSubview:self.scrollView];
	
	// Content View
	self.contentView = [[UIView alloc] init];
	self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.scrollView addSubview:self.contentView];
	
	// URL Text Field
	self.urlTextField = [[UITextField alloc] init];
	self.urlTextField.translatesAutoresizingMaskIntoConstraints = NO;
	self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
	self.urlTextField.placeholder = @"Masukkan URL gambar (contoh: https://picsum.photos/200/300)";
	self.urlTextField.text = @"https://picsum.photos/200/300";
	self.urlTextField.keyboardType = UIKeyboardTypeURL;
	self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.urlTextField.returnKeyType = UIReturnKeyDone;
	self.urlTextField.delegate = self;
	self.urlTextField.font = [UIFont systemFontOfSize:16];
	[self.contentView addSubview:self.urlTextField];
	
	// Get Image Button
	self.getImageButton = [UIButton buttonWithType:UIButtonTypeSystem];
	self.getImageButton.translatesAutoresizingMaskIntoConstraints = NO;
	[self.getImageButton setTitle:@"Get Image" forState:UIControlStateNormal];
	[self.getImageButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.getImageButton.backgroundColor = [UIColor systemBlueColor];
	self.getImageButton.layer.cornerRadius = 8.0;
	self.getImageButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
	self.getImageButton.contentEdgeInsets = UIEdgeInsetsMake(12, 16, 12, 16);
	[self.getImageButton addTarget:self action:@selector(getImageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self.contentView addSubview:self.getImageButton];
	
	// Clear Cache Button
	self.clearCacheButton = [UIButton buttonWithType:UIButtonTypeSystem];
	self.clearCacheButton.translatesAutoresizingMaskIntoConstraints = NO;
	[self.clearCacheButton setTitle:@"Clear Cache" forState:UIControlStateNormal];
	[self.clearCacheButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.clearCacheButton.backgroundColor = [UIColor systemOrangeColor];
	self.clearCacheButton.layer.cornerRadius = 8.0;
	self.clearCacheButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
	self.clearCacheButton.contentEdgeInsets = UIEdgeInsetsMake(12, 16, 12, 16);
	[self.clearCacheButton addTarget:self action:@selector(clearCacheButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self.contentView addSubview:self.clearCacheButton];
	
	// Status Label
	self.statusLabel = [[UILabel alloc] init];
	self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.statusLabel.text = @"Masukkan URL dan klik Get Image";
	self.statusLabel.textAlignment = NSTextAlignmentCenter;
	self.statusLabel.textColor = [UIColor secondaryLabelColor];
	self.statusLabel.font = [UIFont systemFontOfSize:14];
	self.statusLabel.numberOfLines = 0;
	[self.contentView addSubview:self.statusLabel];
	
	// Loading Indicator
	self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
	self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
	self.loadingIndicator.hidesWhenStopped = YES;
	[self.contentView addSubview:self.loadingIndicator];
	
	// URL Image Label
	self.urlImageLabel = [[UILabel alloc] init];
	self.urlImageLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.urlImageLabel.text = @"Gambar dari URL:\n(Komponen: UIImageView + UIImage imageWithData:)";
	self.urlImageLabel.font = [UIFont boldSystemFontOfSize:14];
	self.urlImageLabel.textColor = [UIColor labelColor];
	self.urlImageLabel.numberOfLines = 0;
	[self.contentView addSubview:self.urlImageLabel];
	
	// URL Image View
	self.urlImageView = [[UIImageView alloc] init];
	self.urlImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.urlImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.urlImageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
	self.urlImageView.layer.cornerRadius = 8.0;
	self.urlImageView.clipsToBounds = YES;
	self.urlImageView.hidden = YES;
	[self.contentView addSubview:self.urlImageView];
	
	// Cache Image Label
	self.cacheImageLabel = [[UILabel alloc] init];
	self.cacheImageLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.cacheImageLabel.text = @"Gambar dari Cache:\n(Komponen: UIImageView + UIImage imageWithContentsOfFile:)";
	self.cacheImageLabel.font = [UIFont boldSystemFontOfSize:14];
	self.cacheImageLabel.textColor = [UIColor labelColor];
	self.cacheImageLabel.numberOfLines = 0;
	[self.contentView addSubview:self.cacheImageLabel];
	
	// Cache Image View
	self.cacheImageView = [[UIImageView alloc] init];
	self.cacheImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.cacheImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.cacheImageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
	self.cacheImageView.layer.cornerRadius = 8.0;
	self.cacheImageView.clipsToBounds = YES;
	self.cacheImageView.hidden = YES;
	[self.contentView addSubview:self.cacheImageView];
	
	// HTML5 Image Label
	self.html5ImageLabel = [[UILabel alloc] init];
	self.html5ImageLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.html5ImageLabel.text = @"Gambar dari HTML5 (file://):\n(Komponen: WKWebView + HTML5 <img> tag)";
	self.html5ImageLabel.font = [UIFont boldSystemFontOfSize:14];
	self.html5ImageLabel.textColor = [UIColor labelColor];
	self.html5ImageLabel.numberOfLines = 0;
	[self.contentView addSubview:self.html5ImageLabel];
	
	// HTML5 WebView
	WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
	webConfig.allowsInlineMediaPlayback = YES;
	webConfig.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
	
	self.html5WebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) configuration:webConfig];
	self.html5WebView.translatesAutoresizingMaskIntoConstraints = NO;
	self.html5WebView.backgroundColor = [UIColor secondarySystemBackgroundColor];
	self.html5WebView.layer.cornerRadius = 8.0;
	self.html5WebView.clipsToBounds = YES;
	self.html5WebView.scrollView.scrollEnabled = NO;
	self.html5WebView.scrollView.bounces = NO;
	self.html5WebView.hidden = YES;
	[self.contentView addSubview:self.html5WebView];
}

- (void)setupConstraints {
	[NSLayoutConstraint activateConstraints:@[
		// Scroll View
		[self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
		[self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
		
		// Content View
		[self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
		[self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
		[self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
		[self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
		[self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
		
		// URL Text Field
		[self.urlTextField.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20],
		[self.urlTextField.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.urlTextField.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		[self.urlTextField.heightAnchor constraintEqualToConstant:44],
		
		// Get Image Button
		[self.getImageButton.topAnchor constraintEqualToAnchor:self.urlTextField.bottomAnchor constant:16],
		[self.getImageButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.getImageButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		[self.getImageButton.heightAnchor constraintEqualToConstant:50],
		
		// Clear Cache Button
		[self.clearCacheButton.topAnchor constraintEqualToAnchor:self.getImageButton.bottomAnchor constant:12],
		[self.clearCacheButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.clearCacheButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		[self.clearCacheButton.heightAnchor constraintEqualToConstant:50],
		
		// Status Label
		[self.statusLabel.topAnchor constraintEqualToAnchor:self.clearCacheButton.bottomAnchor constant:16],
		[self.statusLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.statusLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		
		// Loading Indicator
		[self.loadingIndicator.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:8],
		[self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
		
		// URL Image Label
		[self.urlImageLabel.topAnchor constraintEqualToAnchor:self.loadingIndicator.bottomAnchor constant:20],
		[self.urlImageLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.urlImageLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		
		// URL Image View
		[self.urlImageView.topAnchor constraintEqualToAnchor:self.urlImageLabel.bottomAnchor constant:8],
		[self.urlImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.urlImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		[self.urlImageView.heightAnchor constraintEqualToConstant:250],
		
		// Cache Image Label
		[self.cacheImageLabel.topAnchor constraintEqualToAnchor:self.urlImageView.bottomAnchor constant:20],
		[self.cacheImageLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.cacheImageLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		
		// Cache Image View
		[self.cacheImageView.topAnchor constraintEqualToAnchor:self.cacheImageLabel.bottomAnchor constant:8],
		[self.cacheImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.cacheImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		[self.cacheImageView.heightAnchor constraintEqualToConstant:250],
		
		// HTML5 Image Label
		[self.html5ImageLabel.topAnchor constraintEqualToAnchor:self.cacheImageView.bottomAnchor constant:20],
		[self.html5ImageLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.html5ImageLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		
		// HTML5 WebView
		[self.html5WebView.topAnchor constraintEqualToAnchor:self.html5ImageLabel.bottomAnchor constant:8],
		[self.html5WebView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
		[self.html5WebView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
		[self.html5WebView.heightAnchor constraintEqualToConstant:250],
		[self.html5WebView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20]
	]];
}

- (void)setupKeyboardHandling {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	tapGesture.cancelsTouchesInView = NO;
	[self.view addGestureRecognizer:tapGesture];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	NSDictionary *userInfo = notification.userInfo;
	CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat keyboardHeight = keyboardFrame.size.height;
	
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
	self.scrollView.contentInset = contentInsets;
	self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification {
	self.scrollView.contentInset = UIEdgeInsetsZero;
	self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)dismissKeyboard {
	[self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - Button Actions

- (void)getImageButtonTapped:(UIButton *)sender {
	[self dismissKeyboard];
	
	NSString *urlString = [self.urlTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (urlString.length == 0) {
		[self updateStatus:@"URL tidak boleh kosong" withError:YES];
		return;
	}
	
	// Check cache first
	if ([self.cacheManager hasCachedImageForURL:urlString]) {
		UIImage *cachedImage = [self.cacheManager cachedImageForURL:urlString];
		if (cachedImage) {
			// Show cached image from file
			NSString *cachePath = [self.cacheManager cachePathForURL:urlString];
			self.cacheImageView.image = cachedImage;
			self.cacheImageView.hidden = NO;
			self.cacheImageLabel.text = [NSString stringWithFormat:@"Gambar dari Cache:\n(Komponen: UIImageView + UIImage imageWithContentsOfFile:)\n%@", cachePath];
			
			// Load HTML5 from file://
			[self loadHTML5FromCachePath:cachePath];
			
			// Also load from URL to show comparison
			[self updateStatus:@"Gambar dimuat dari cache, memuat ulang dari URL untuk perbandingan..." withError:NO];
			[self.loadingIndicator startAnimating];
			self.getImageButton.enabled = NO;
			[self fetchImageWithURL:urlString];
			return;
		}
	}
	
	[self updateStatus:@"Mengambil gambar..." withError:NO];
	[self.loadingIndicator startAnimating];
	self.getImageButton.enabled = NO;
	self.urlImageView.hidden = YES;
	self.cacheImageView.hidden = YES;
	self.html5WebView.hidden = YES;
	
	// Handle redirect and get final URL, then download to cache
	[self fetchImageWithURL:urlString];
}

- (void)clearCacheButtonTapped:(UIButton *)sender {
	[self.cacheManager clearCache];
	[self updateStatus:@"Cache berhasil dibersihkan" withError:NO];
	self.urlImageView.hidden = YES;
	self.cacheImageView.hidden = YES;
	self.html5WebView.hidden = YES;
	self.urlImageLabel.text = @"Gambar dari URL:\n(Komponen: UIImageView + UIImage imageWithData:)";
	self.cacheImageLabel.text = @"Gambar dari Cache:\n(Komponen: UIImageView + UIImage imageWithContentsOfFile:)";
	self.html5ImageLabel.text = @"Gambar dari HTML5 (file://):\n(Komponen: WKWebView + HTML5 <img> tag)";
	self.currentImageURL = nil;
}

#pragma mark - HTML5 Methods

- (void)loadHTML5FromCachePath:(NSString *)cachePath {
	if (!cachePath || cachePath.length == 0) {
		return;
	}
	
	// Convert to file:// URL
	NSURL *fileURL = [NSURL fileURLWithPath:cachePath];
	NSString *fileURLString = [fileURL absoluteString];
	
	// Create HTML with img tag using file://
	NSString *htmlString = [NSString stringWithFormat:
		@"<!DOCTYPE html>"
		@"<html>"
		@"<head>"
		@"<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>"
		@"<style>"
		@"body { margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; min-height: 100vh; background-color: transparent; }"
		@"img { max-width: 100%%; max-height: 100%%; object-fit: contain; }"
		@"</style>"
		@"</head>"
		@"<body>"
		@"<img src='%@' alt='Cached Image' />"
		@"</body>"
		@"</html>", fileURLString];
	
	// Load HTML in WebView
	[self.html5WebView loadHTMLString:htmlString baseURL:nil];
	self.html5WebView.hidden = NO;
	self.html5ImageLabel.text = [NSString stringWithFormat:@"Gambar dari HTML5 (file://):\n(Komponen: WKWebView + HTML5 <img> tag)\n%@", fileURLString];
}

#pragma mark - Network Methods

- (void)fetchImageWithURL:(NSString *)urlString {
	NSURL *url = [NSURL URLWithString:urlString];
	if (!url) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateStatus:@"URL tidak valid" withError:YES];
			[self.loadingIndicator stopAnimating];
			self.getImageButton.enabled = YES;
		});
		return;
	}
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.loadingIndicator stopAnimating];
				self.getImageButton.enabled = YES;
				[self updateStatus:[NSString stringWithFormat:@"Error: %@", error.localizedDescription] withError:YES];
			});
			return;
		}
		
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
			// Get final URL after redirect
			NSString *finalURL = response.URL.absoluteString;
			
			// Show image from URL first
			UIImage *urlImage = [UIImage imageWithData:data];
			if (urlImage) {
				dispatch_async(dispatch_get_main_queue(), ^{
					self.urlImageView.image = urlImage;
					self.urlImageView.hidden = NO;
					self.urlImageLabel.text = [NSString stringWithFormat:@"Gambar dari URL:\n(Komponen: UIImageView + UIImage imageWithData:)\n%@", finalURL];
					self.currentImageURL = urlString;
				});
			}
			
			// Save to cache using original URL (for cache key)
			[self.cacheManager saveImageData:data forURL:urlString completion:^(BOOL success, NSString *cachePath) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.loadingIndicator stopAnimating];
					self.getImageButton.enabled = YES;
					
					if (success) {
						// Load image from cache
						UIImage *cachedImage = [self.cacheManager cachedImageForURL:urlString];
						if (cachedImage) {
							self.cacheImageView.image = cachedImage;
							self.cacheImageView.hidden = NO;
							self.cacheImageLabel.text = [NSString stringWithFormat:@"Gambar dari Cache:\n(Komponen: UIImageView + UIImage imageWithContentsOfFile:)\n%@", cachePath];
							
							// Load HTML5 from file://
							[self loadHTML5FromCachePath:cachePath];
							
							[self updateStatus:[NSString stringWithFormat:@"Gambar berhasil dimuat dan disimpan ke cache\nURL: %@", finalURL] withError:NO];
						} else {
							// Fallback: use URL image for cache view too
							if (urlImage) {
								self.cacheImageView.image = urlImage;
								self.cacheImageView.hidden = NO;
								self.cacheImageLabel.text = @"Gambar dari Cache: (Gagal memuat dari cache, menampilkan dari URL)";
							}
							[self updateStatus:[NSString stringWithFormat:@"Gambar berhasil dimuat\nURL: %@", finalURL] withError:NO];
						}
					} else {
						// Fallback: use URL image for cache view too
						if (urlImage) {
							self.cacheImageView.image = urlImage;
							self.cacheImageView.hidden = NO;
							self.cacheImageLabel.text = @"Gambar dari Cache: (Gagal menyimpan ke cache)";
						}
						[self updateStatus:[NSString stringWithFormat:@"Gambar berhasil dimuat (cache gagal)\nURL: %@", finalURL] withError:NO];
					}
				});
			}];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.loadingIndicator stopAnimating];
				self.getImageButton.enabled = YES;
				[self updateStatus:[NSString stringWithFormat:@"HTTP Error: %ld", (long)httpResponse.statusCode] withError:YES];
			});
		}
	}];
	
	[task resume];
}


- (void)updateStatus:(NSString *)status withError:(BOOL)isError {
	self.statusLabel.text = status;
	self.statusLabel.textColor = isError ? [UIColor systemRedColor] : [UIColor labelColor];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
