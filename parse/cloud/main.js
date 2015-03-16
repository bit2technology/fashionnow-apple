
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
    response.success("Hello world! Eh nooois");
});

Parse.Cloud.define("sendPush", function(request, response) {
    var query = new Parse.Query(Parse.Installation);
    query.containedIn("userId", request.params.userIds);

    Parse.Push.send({
        where: query,
        data: {
            alert: request.params.senderName + " precisa de ajuda!"
        }
    },{
        succes: function() {
            // Push successfull
            response.success("Push sent");
        },
        error: function(error) {
            // Handle error
            response.error("Error");
        }
    })
});

//IDEIA: UM CLOUD CODE QUE DEVOLVE O COUNT DAS DUAS OPCOES DA ENQUETE

Parse.Cloud.define("getPollVoteList", function(request, response) {
	var query = new Parse.Query("Poll")
	query.include("createdBy")
	query.include("photos")
	query.descending("createdAt")
	var user = new Parse.User()
	user.set("id", request.params.userId)
	query.notEqualTo("createdBy", user)
	query.find({
    	success: function(results) {
    		response.success(results);
    	},
    	error: function() {
      		response.error("Query failed");
    	}
  	});
})