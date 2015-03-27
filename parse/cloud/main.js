Parse.Cloud.define("sendPush", function (request, response) {
    var query = new Parse.Query(Parse.Installation);
    query.containedIn("userId", request.params.userIds);

    Parse.Push.send({
        where: query,
        data: {
            alert: request.params.senderName + " precisa de ajuda!",
            badge: "Increment"
        }
    }, {
        succes: function () {
            // Push successfull
            response.success("Push sent");
        },
        error: function (error) {
            // Handle error
            response.error("Error");
        }
    });
});

//IDEIA: UM CLOUD CODE QUE DEVOLVE O COUNT DAS DUAS OPCOES DA ENQUETE

Parse.Cloud.afterSave("Poll", function (request, response) {
    var query = new Parse.Query(Parse.Installation);
    query.containedIn("userId", request.object.get("userIds"));
    Parse.Push.send({
        where: query,
        data: {
            alert: request.user.get("name") + " precisa de ajuda!",
            badge: "Increment"
        }
    }, {
        succes: function () {
            // Push successfull
            response.success("Push sent");
        },
        error: function (error) {
            // Handle error
            response.error("Error send push");
        }
    });
});