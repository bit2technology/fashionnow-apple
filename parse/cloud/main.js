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
    
    query.containedIn("userId", request.params.to);

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
            response.success("Push sent");
        },
        error: function (error) {
            // Handle error
            response.error("Error: " + error);
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

Parse.Cloud.afterSave("Poll", function (request) {
    "use strict";
    
    if ((request.object.get("version") <= 1) && !request.object.get("hidden")) {
        
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
                console.log("Push sent");
            },
            error: function (error) {
                // Handle error
                console.error("Error send push");
            }
        });
    }
});

Parse.Cloud.beforeSave("Vote", function (request, response) {
    "use strict";
    
    if (!request.object.get("pollCreatedBy")) {
        
        var query = new Parse.Query("Poll").include("createdBy").select(["createdBy"]).get(request.object.get("pollId"), {
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