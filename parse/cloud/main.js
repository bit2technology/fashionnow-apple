/* global Parse */
/* global Parse */

Parse.Cloud.define("sendPush", function (request, response) {
    "use strict";
    var query = new Parse.Query(Parse.Installation),
        locKey = "P002",
        locArgs = [request.params.from];
    
    // Change notification style if there is a caption
    if (request.params.caption) {
        locKey = "P003";
        locArgs.push(request.params.caption);
    }
    
    query.containedIn("userId", request.params.to)
         .notEqualTo("appVersion", "1785");

    Parse.Push.send({
        where: query,
        data: {
            alert: {
                "title-loc-key": "P001",
                "loc-key": locKey,
                "loc-args": locArgs
            },
            badge: "Increment",
            poll: request.params.poll
        }
    }, {
        success: function () {
            // Push successfull
            response.success("sendPush successful");
        },
        error: function (error) {
            // Handle error
            response.error("sendPush error: " + error);
        }
    });
});

Parse.Cloud.define("resendVerification", function (request, response) {
    "use strict";
    
    if (!request.user) {
        response.error("resendVerification error: no user");
    }
    
    var emailBkp = request.user.get("email");
    request.user.save("email", null, {
        success: function () {
            // First save successful
            request.user.save("email", emailBkp, {
                success: function () {
                    // Second save successful
                    response.success("resendVerification successful");
                },
                error: function (error) {
                    // Handle error
                    response.error("resendVerification 2 error: " + error);
                }
            });
        },
        error: function (error) {
            // Handle error
            response.error("resendVerification 1 error: " + error);
        }
    });
});

Parse.Cloud.define("deviceLocations", function (request, response) {
    "use strict";
    
    var query = new Parse.Query(Parse.Installation)
        .select("location")
        .exists("location")
        .limit(1000);
    
    query.find({
        useMasterKey: true,
        success: function (results) {
            // Second save successful
            response.success(results);
        },
        error: function (error) {
            // Handle error
            response.error("deviceLocations error: " + error);
        }
    });
    
    
    
//    var error: NSError?
//            var locations = [UserAnnotation]()
//            
//
//            while error == nil {
//                if let results = query.findObjects(&error) as? [ParseInstallation] {
//                    if results.count == 0 {
//                        break
//                    }
//                    jump += results.count
//
//                    for result in results {
//                        if let location = result.location {
//                            locations.append(UserAnnotation(latitude: location.latitude, longitude: location.longitude))
//                        }
//                    }
//
//                } else {
//                    break
//                }
//            }
});

Parse.Cloud.beforeSave(Parse.User, function (request, response) {
    "use strict";
    
    // Get Facebook authorization info
    var auth = request.object.get("authData"),
        facebookAuth = auth ? auth.facebook : null;
    // Update facebookId
    request.object.set("facebookId", facebookAuth ? facebookAuth.id : null);
                       
    response.success();
});

// ####################### COMPATIBILITY WITH OLD VERSIONS ###############################

Parse.Cloud.afterSave("Poll", function (request) {
    "use strict";
    
    if (!(request.object.get("version") > 1)) {
        
        var query = new Parse.Query(Parse.Installation);
        query.containedIn("userId", request.object.get("userIds"));
        
        Parse.Push.send({
            where: query,
            data: {
                alert: (request.user ? request.user.get("name") : "Um amigo") + " precisa de ajuda" + (request.object.get("caption") ? ": \"" + request.object.get("caption") + "\"" : ""),
                badge: "Increment"
            }
        }, {
            success: function () {
                // Push successfull
                console.log("Poll afterSave successful");
            },
            error: function (error) {
                // Handle error
                console.error("Poll afterSave error: " + error);
            }
        });
    }
});

Parse.Cloud.beforeSave("Vote", function (request, response) {
    "use strict";
    
    if (!request.object.get("pollCreatedBy")) {
        
        new Parse.Query("Poll").include("createdBy").select(["createdBy"]).get(request.object.get("pollId"), {
            success: function (poll) {
                request.object.set("pollCreatedBy", poll.get("createdBy").id);
                request.object.set("pollCreatedAt", poll.createdAt);
                response.success();
            },
            error: function (poll, error) {
                response.error("Get poll" + poll + " error " + error);
            }
        });
    } else {
        response.success();
    }
});

//Parse.Cloud.afterSave("Vote", function (request) {
//    "use strict";
//    
//    if (request.object.get("vote") > 0) {
//    
//        var query = new Parse.Query(Parse.Installation);
//        query.equalTo("userId", request.object.get("userId"));
//
//        Parse.Push.send({
//            where: query,
//            data: {
//                alert: "Sua enquete recebeu um voto",
//                badge: "Increment"
//            }
//        }, {
//            success: function () {
//                console.log("Push sent");
//            },
//            error: function (error) {
//                console.error("Push error " + error);
//            }
//        });
//    }
//});