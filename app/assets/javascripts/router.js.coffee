# class ConsiderIt.Router extends Backbone.Router
#   routes : 
#     ":proposal": "Consider"
#     ":proposal/results": "Aggregate"
#     ":proposal/points/:point" : "PointDetails"
#     ":proposal/positions/:user_id" : "StaticPosition"

#     "dashboard/application" : "AppSettings"
#     "dashboard/proposals" : "ManageProposals"
#     "dashboard/roles" : "UserRoles"
#     "dashboard/users/:id/profile" : "Profile"
#     "dashboard/users/:id/profile/edit" : "EditProfile"
#     "dashboard/users/:id/profile/edit/account" : "AccountSettings"
#     "dashboard/users/:id/profile/edit/notifications" : "EmailNotifications"
#     "dashboard/analytics" : "Analyze"
#     "dashboard/data" : "Database"
#     "dashboard/moderate" : "Moderate"
#     "dashboard/assessment" : "Assess"
#     "" : "Root"

#   valid_endpoint : (path) ->
#     parts = path.split('/')
#     return true if parts.length == 1
#     if parts[1] == 'dashboard'
#       return _.contains(['profile', 'edit', 'account', 'application', 'proposals', 'roles', 'notifications', 'analytics', 'data', 'moderate', 'assessment'], parts[parts.length-1])  

#     else
#       return !_.contains(['positions', 'points'], parts[parts.length-1])