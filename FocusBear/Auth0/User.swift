import JWTDecode

struct AuthUser {
    let id: String
    let name: String
    let email: String
    let emailVerified: String
    let picture: String
    let updatedAt: String
    let subscriptionStatus:[String:Any]
    let userId: String
}

extension AuthUser {
    init?(from idToken: String) {
        guard let jwt = try? decode(jwt: idToken),
              let id = jwt.subject
               else {
            return nil
        }
        let name = jwt.claim(name: "name").string ?? ""
        let email = jwt.claim(name: "email").string ?? ""
        let emailVerified = jwt.claim(name: "email_verified").boolean ?? false
        let picture = jwt.claim(name: "picture").string ?? ""
        let updatedAt = jwt.claim(name: "updated_at").string ?? ""
        var userId = ""
        var subscriptionInfo = [String:Any]()
        if let info = jwt.claim(name: "https://eyst-backend-prod-8th3.onrender.com/user").rawValue as? [String:Any]{
            if let subscriptionStatus = info["subscriptionStatus"] as? [String :Any]{
                subscriptionInfo = subscriptionStatus
            }
            if let id = info["id"] as? String{
                userId = id
            }
        }
        
        self.id = id
        self.name = name
        self.email = email
        self.emailVerified = String(describing: emailVerified)
        self.picture = picture
        self.updatedAt = updatedAt
        self.subscriptionStatus = subscriptionInfo
        self.userId = userId
    }
}
