class ConsiderIt.Router extends Backbone.Router
  routes : 
    ":proposal": "Consider"
    ":proposal/results": "Aggregate"
    ":proposal/points/:point" : "PointDetails"

    "dashboard/application" : "AppSettings"
    "dashboard/proposals" : "ManageProposals"
    "dashboard/roles" : "UserRoles"
    "dashboard/users/:id/profile" : "Profile"
    "dashboard/users/:id/profile/edit" : "EditProfile"
    "dashboard/users/:id/profile/edit/account" : "AccountSettings"
    "dashboard/users/:id/profile/edit/notifications" : "EmailNotifications"
    "dashboard/analytics" : "Analyze"
    "dashboard/data" : "Database"
    "dashboard/moderate" : "Moderate"
    "dashboard/assessment" : "Assess"