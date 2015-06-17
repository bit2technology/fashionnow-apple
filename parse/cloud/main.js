/* global Parse */
/* global Parse */

Parse.Cloud.define("followUser", function (request, response) {
    "use strict";
    
    if (!request.user) {
        response.error("No user");
    } else if (!request.params.follow) {
        response.error("Parameter missing: follow - User to follow");
    }
    
    var query = new Parse.Query(Parse.Installation),
        locArgs = [request.user.get("name") || request.user.get("username")];
    
    // Configure query and remove unsuported versions
    query.equalTo("userId", request.params.follow)
         .greaterThanOrEqualTo("pushVersion", 2);

    Parse.Push.send({
        where: query,
        data: {
            alert: {
                "title-loc-key": "P004",
                "loc-key": "P005",
                "loc-args": locArgs
            },
            badge: "Increment",
            follower: request.user.id
        }
    }, {
        success: function () {
            // Push successfull
            response.success("Success");
        },
        error: function (error) {
            // Handle error
            response.error("Error: " + error);
        }
    });
});

Parse.Cloud.define("pollPosted", function (request, response) {
    "use strict";
    
    if (!request.user) {
        response.error("No user");
    } else if (!request.params.to) {
        response.error("Parameter missing: to - Array of user IDs to send the notification");
    } else if (!request.params.poll) {
        response.error("Parameter missing: poll - Poll ID");
    }
    
    var query = new Parse.Query(Parse.Installation),
        locKey = "P002",
        locArgs = [request.user.get("name") || request.user.get("username")];
    
    // Change notification style if there is a caption
    if (request.params.caption) {
        locKey = "P003";
        locArgs.push(request.params.caption);
    }
    
    // Configure query and remove unsuported versions
    query.containedIn("userId", request.params.to)
         .greaterThanOrEqualTo("pushVersion", 1);

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
            response.success("Success");
        },
        error: function (error) {
            // Handle error
            response.error(error);
        }
    });
});

Parse.Cloud.define("resendVerification", function (request, response) {
    "use strict";
    
    if (!request.user) {
        response.error("No user");
    } else if (!request.user.get("email")) {
        response.error("User has no email");
    }
    
    var emailBkp = request.user.get("email");
    request.user.save("email", null, {
        success: function () {
            // First save successful
            request.user.save("email", emailBkp, {
                success: function () {
                    // Second save successful
                    response.success("Success");
                },
                error: function (error) {
                    // Handle error
                    response.error("Error Save 2: " + error);
                }
            });
        },
        error: function (error) {
            // Handle error
            response.error("Error Save 1: " + error);
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
            response.success(results);
        },
        error: function (error) {
            response.error(error);
        }
    });
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

Parse.Cloud.beforeSave(Parse.Installation, function (request, response) {
    "use strict";
    
    // Get Facebook authorization info
    if (!request.object.get("pushVersion")) {
        request.object.set("pushVersion", request.object.get("appVersion") >= 2607 ? 1 : 0);
    }
                       
    response.success();
});

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
         .greaterThanOrEqualTo("pushVersion", 1);

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