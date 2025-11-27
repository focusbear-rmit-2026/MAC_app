//
//  buddyData.swift
//  FocusBear
//
//  Created by Manish Jain on 17/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//
// added on 18/11/25 v2.27.432
struct Buddy{
    var buddyUserId: String
    var buddyEmail: String
    var invitationStatus: String
}
var arrAllBuddies = [Buddy]()

func convertJsonToBuddies(json:[NSDictionary]){
    arrAllBuddies.removeAll()
    for dic in json{
        let buddy_email = dic.value(forKey: "buddy_email") as? String ?? ""
        let buddy_user_id = dic.value(forKey: "buddy_user_id") as? String ?? ""
        let invitation_status = dic.value(forKey: "invitation_status") as? String ?? ""
        if invitation_status.lowercased() == "accepted"{
            let buddy = Buddy(buddyUserId: buddy_user_id, buddyEmail: buddy_email, invitationStatus: invitation_status)
            arrAllBuddies.append(buddy)
        }
    }
}
/*
 [{
     "buddy_email" = "manish@focusbear.io";
     "buddy_user_id" = "f255d04d-c45a-4114-b68c-1b4682e15bbe";
     "created_at" = "2025-11-17T13:21:40.648Z";
     id = "66ecfd6b-b0f7-4bcf-bee8-ce26975f8f75";
     "invitation_responded_at" = "<null>";
     "invitation_sent_at" = "2025-11-17T13:21:40.646Z";
     "invitation_status" = pending;
     "updated_at" = "2025-11-17T13:21:40.648Z";
     "user_id" = "2dea5fbc-e0a1-4cf0-ba0d-d288fd0e824d";
 }]
 */
