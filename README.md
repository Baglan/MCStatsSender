# MCStatsSender

Goal of this project is to make a very simple utility class for sending app usage statistics.

## Installation

In you app, copy file from the 'Classes' folder to your project.

Server part will also need to be set up. In the 'PHP' folder, there is a sample script for saving the data to a log file.

## Usage

    #import "MCStatsSender.h"
    
MCStatsSender has to be initialized with URL before it is used:

    [MCStatsSender setServiceURL:[NSURL URLWithString:@"http://your.server.url/stats.php"]];
    
Call one of these methods to send reports:

    + (void)sendData:(NSDictionary *)data;
    + (void)sendAction:(NSString *)action withData:(NSDictionary *)data;
    + (void)sendAction:(NSString *)action;
    
For example, here's how lot log a user action:

    [MCStatsSender sendAction:@"started"];
    
## Data
    
Data is sent in a POST request. The body of the request contains supplied data in JSON format. Some common data is sent in HTTP headers:

1. X-MCSTATSSENDER_UNIQUEID: Unique ID generated for each app installation;
2. X-MCSTATSSENDER_SYSTEM: OS type and version;
3. X-MCSTATSSENDER_DEVICE: device (e.g. "iPod touch");
4. X-MCSTATSSENDER_PRODUCT: product bundle name and version;
5. X-MCSTATSSENDER_SCREEN_SIZE: device screen size;
6. X-MCSTATSSENDER_MACHINE_NAME: device machine name (a more precise way to identify hardware);
7. X-MCSTATSSENDER_COMPROMIZED: a hint on whether the app has been compromized;
8. X-MCSTATSSENDER_REACHABILITY: current reachability status (WiFi, WWAN or NO – of "NO" will never be sent).

Here's the sample data generated by the stats.php:

    {"action":"started","time":"2012-10-26 00:24:04","product":"MCStatsSender 1.0","system":"iPhone OS 6.0","device":"iPod touch","uniqueId":"099DD45B-FA08-4694-87C3-8BE99DBA0B82-3951-00001DAE562E4307","screenSize":"768 x 1024 x 1.0","machineName":"iPad2,7","compromized":"NO","reachability":"WiFi"}

## License

This code is available under the MIT license