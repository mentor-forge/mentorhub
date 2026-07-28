---
tags:
date: 2026-07-21 11:38
type: encounter
summary: They decided to simplify the data model by removing card and dashboard collections, embedding subscriptions in the customer entity, adding a payments collection for Stripe webhooks, and tasked Mary with researching the exact Stripe and Cognito integration details.
---
tags: [[🗣 Encounters MOC]]
Date: [[2026-07-21]]

## **Attendees**: 
- [[Mike Storey (Me)]]
- [[Mary Anderson]]

## Summary by gpt-oss:120b
**Summary** Mike and Mary start with casual chat about noisy landscaping outside Mike’s house, then move into a work session focused on the MentorHub project. Mary wants help finishing the FWO2 tickets, and Mike walks her through his mental model for breaking down UI pages, APIs, and data structures. They agree that storing credit‑card data in Stripe is preferable, so they plan to drop the “card” collection, eliminate the customizable dashboard for the MVP, and move subscription information into the customer document. Mike suggests adding a new collection (e.g., “payments”) to capture Stripe webhook events and outlines how the checkout flow should forward a shopping‑cart payload to Stripe and receive payment results via webhooks. He also notes similar needs for Cognito account creation/update data. Both decide to update the ERD accordingly, clean up unused workspace files, and have Mary record all research findings (Stripe checkout workflow, webhook payloads, Cognito requirements) in Obsidian/Cursor as task items before any schema changes are made. 
## Agenda/Questions
- What do you want to focus on today?
- How would you describe what's happening now?
- During our time together, what would you like to accomplish?
- What would you like to be able to share next time?
- How are your discoveries making a difference?
- How do you want to wrap up today?

## Transcript
#### Mike
I'm good. We've got landscaping going on right outside my door today, so it might be a little noisy. 

#### Mary
I don't hear anything. 

#### Mike
Well, the chainsaws are running, and I can already tell you, it already looks so much better. Look at that one go. So my house is at the top of the hill, top of the mountain. 

#### Mary
I don't hear anything. 

#### Mike
And so at the back of my house, it goes downhill really, really fast. And we would have an amazing view, except there's all these trees covered in vines, like maybe 50 feet behind my house. And my next door neighbor just paid some people to go cut all those trees down. 

#### Mary
Oh. 

#### Mike
The thing about it is those trees are not on our property. Those trees are on city property. So I have been afraid to do it. But she wasn't. 

#### Mary
Oh. 

#### Mike
She wasn't. She's like, I'm required. I'm retired. The trees are going to go back. What are they going to do to me? 

#### Mary
What? 

#### Mike
So she got some people and hired some people. And I hope they clean up the park that's in our property because the stuff that's inside our zone is just covered in vines and little short trees and stuff. And I won't be terribly upset if they don't, but they have cut down the big trees that were blocking my view. depending on whether or not they get that next set of little trees right there, I could have an amazing new view. But I've already got some improvements. So I'm excited and watching them cut things down and listening to the chainsaws. 

#### Mary
It's got you excited. 

#### Mike
Yeah. Well, the first tree they cut down I thought was really cool because they cut it down and it went down and it only got about three quarters of the way down and it had so many vines on it that the vines were keeping it from falling. So they had to come around one side and cut the vine so it could get the rest of the way down. But, yeah, I think it's going to be really nice. All right. So, what would you like to focus on today? 

#### Mary
finishing FWO2 

#### Mary
and the tickets that follow behind it because I can't get to those if I get that out the way so whatever I can do that you can help me 

#### Mary
like not help no like help guide you know like walk me through it That way, you know, you don't have to watch over my back all the time. You know, look over my shoulder. 

#### Mike
Yeah, this part of design is hard to describe. And so I want to teach you what I would do, but I'm not sure how to give you instructions to do what I would do. Does that make sense? 

#### Mary
Yeah, like only you know how to do it. 

#### Mike
I know how to do it. I know how to do sort of it. 

#### Mary
And... 

#### Mike
I don't think anybody's an expert at this. And the way I do it is not something that I could easily tell you to do. The way that I would do wrapping up W02, the real ultimate outcome for W02 needs to be a series of tickets associated with the UI and the pages on the UI. I usually do one ticket per page. The API that supports that UI, got to think through what does that API need to do? Where does that API need to combine different data to support that front end? And then I got to think about the data and the database structure. And for that, I'm thinking about what's the information that needs to be on the screen versus what's the information that needs to be in the API. one way to collect that information is to write down the user journey. The user goes to this page and does this, and then they go to this page and does this, and then they go to this page and does this. And then with each one of those pages, we can say, okay, what is the data that they need to do that thing? Oh, well, they need a customer ID and they need a shipping address and they need a where, or a Stripe user ID or a Stripe customer ID. So then they go to this page and do this, and then they go to this page and do this. And so we kind of need to build out all of those issues to create the pages, to update the API that's backing the pages, and to create the data and test data that those pages and UI are going to need. So let's talk about this for a minute because I think one of the things that Cursor identified early on was that our approach to credit card is probably not appropriate. And if we can get away from storing credit card information and just have all of the credit card information persisted in Stripe and not in our application, then we will avoid a lot of regulatory compliance issues. 

#### Mary
Yeah. Yeah. Mm-hmm. Yeah. 

#### Mike
So I don't understand exactly how that's going to work. I haven't studied the Stripe integration. so I don't know exactly how that's going to work so I think what we can probably do I put a prompt in there 

#### Mary
I have a question. 

#### Mike
go ahead okay go ahead 

#### Mary
I thought. 

#### Mike
yeah 

#### Mary
I'm just brainstorming. 

#### Mike
That's what this session is. 

#### Mary
Right. And what you're promoting. mentor hub the mentorship um i'm just thinking there should is there a way to um from the data that we collect on our end 

#### Mary
it should be just like a basic information of form just the basics you know just the name um email address um and then it should be a somewhere on there um 

#### Mike
Weak. 

#### Mary
where it it will prompt you to basically some kind of button to connect you to stripes so it's not through us us and to connect you to describe any information. 

#### Mike
I think that's so 

#### Mary
So it's not we're keeping the information that goes to another part. 

#### Mike
the way that I think it works and again you need to do the stripe research to be able to say with confidence that this is how it should work but the way that I think it should work and the way I think Stripe is designed is on our webpage, we have a place where they create a shopping cart. And that shopping cart is going to contain a subscription and maybe a quantity and a unit price, however we're going to price this thing out. We're going to have a page somewhere where they say, this is the description I want added to my cart. Now I'm pretty sure what we then do is we pass the information in that cart off to Stripe. So we will forward the user to the Stripe payment page and we will pass that forward in Stripe payment page information about what they're purchasing. And then Stripe will collect the payment and process it will be like the checkout. So if you go to Amazon Web Services, you know there's the one part where you're looking at stuff and adding 

#### Mary
Mm-hmm. 

#### Mike
it to the cart, right? And then you click a checkout button and that takes you to a workflow 

#### Mary
Mm-hmm. 

#### Mike
where you enter your credit card and stuff, right? So I'm pretty sure that that checkout button 

#### Mary
Right. 

#### Mike
is what's going to link you off to Stripe to do the payment. And in order to have a checkout button, we need to have something to put in the checkout, which is going to be a subscription. 

#### Mary
Okay. 

#### Mike
right? And we have a subscription collection, but I'm wondering if that's the best place to source subscription information. What I'm starting to think is that in, because those subscriptions have absolutely no meaning outside the context of the customer, right? If I have a subscription, it doesn't mean anything 

#### Mary
Mm-hmm. 

#### Mike
unless I have the customer with it. And since those two pieces of data are so tightly intertwined, I think that on our customer schema, we should have an array of subscriptions. And a subscription should be the thing that we bill out and save, and then the UI uses that subscription information to make the call out to Stripe. And Stripe makes the payment information. So I think that's how it's supposed to work. I also think that when Stripe processes that payment, if we want to keep our own records of that payment, we need to have a webhook configured so that Stripe can call back to our webhook and say, I just processed this payment. And then we can persist the information from that webhook in a collection somewhere so that we have a history of all of those things. Now, that might need to be a different collection because those receipts will have meaning outside the context of a customer. I may want to do a billing report for all customers. 

#### Mary
Okay. 

#### Mike
So I think that that transaction, whatever it is that comes back over the webhook, is something that we should persist. So somebody needs to go review the Stripe webhooks interface and see what the data structures that the webhook sends back are. And we need to have database structures that match those. And we need to have test data in those data structures. So at this point, it sounds to me like we can drop card, we can add something for the webhooks data. I don't know what it is. 

#### Mary
Yeah. And replace one with the other. 

#### Mike
Well, no, in the configurator, it's better to delete and then create a new one. If you want to rename it, you've got to rename it in a lot of different places. 

#### Mary
Oh. 

#### Mike
And even deleting it, the easiest way to delete it is manually. 

#### Mary
Oh, okay. Mm-hmm. 

#### Mike
So we're going to delete card. We're going to delete subscription and move subscription into customer. A customer has an array of subscriptions. And we're going to need to research what is the data that comes back from Stripe on webhooks 

#### Mary
Okay. 

#### Mike
and document those data structures so that we can save that data. That's all I see in the customer domain. So all the stuff we had in the customer domain, what was that? Let me pull up that ERD. 

#### Mary
Oops. 

#### Mike
ERD. So in the ERD, we had customer, dashboard, subscription, and card. We're going to move subscription into customer. We're going to get rid of card. 

#### Mary
Mm-hmm. 

#### Mike
We're going to add payments, I think is what it's going to be called, maybe. 

#### Mary
Mm-hmm. Oh. 

#### Mike
Because it's the webhook stuff that comes back from Stripe, and it should be coming back from Stripe saying, you got this payment. So research the webhooks, see what the data that comes back is, 

#### Mary
Yeah. 

#### Mike
And then we'll name the collection to store that data accordingly. I think it's going to be payments. It may be payment attempts because when we've got subscriptions and we're charging in the second month, the credit card might be rejected. And we'll get a webhook about that. So maybe we have one collection that has all the different types of data we can store from webhooks. Or maybe webhooks get back different types of data. Maybe they get payments and exceptions. 

#### Mary
Okay. 

#### Mike
The dashboard collection. I think that we can leave the dashboard collection in its current form until we start designing customer dashboards. 

#### Mary
Okay. 

#### Mike
And I want to think about, I want to have a design jam session with the team on the customer dashboard because it's probably one of our more important dashboards. 

#### Mary
Okay. 

#### Mike
So the customer dashboard is going to show us some information that this particular customer is interested in. They might be interested in graphs for each mentee that show how many resources they've touched over the last X number of days. They might be interested in seeing the mentor notes about that mentee. We have to look at all the data we have that a customer might want to view on a dashboard and figure out what the options are. And then the dashboard selection then becomes, this is a combination of different controls. So we're going to display these controls and these controls and these controls. The dashboard saves that configuration, and that's the configuration for that customer's dashboard. And as I think about this more, I think since we're pushing the MVP, let's just drop the customized dashboard idea altogether. The customer gets a customer dashboard. In the future, we can add configurable dashboards. But for our MVP, I don't think we need it. 

#### Mary
Okay. 

#### Mike
We could drop the dashboard collection. So we're going to drop all three of the customer journey cards. And... I want to potentially make a change to the ERD. Can you go look at the ERD for a second? Erd.svg in the root of MongoDB API. 

#### Mary
Something changed on my laptop from last night to this morning. 

#### Mike
Windows is such a weird operating system that if I had a Windows laptop, I would shut it down every night. I would click the shutdown and do the shutdown and let it shut down. And then every morning I would fire it up and I would have a standard routine that I went through to get everything started. 

#### Mary
The task bar at the bottom, 

#### Mike
If it's a... 

#### Mary
The icons was a little bit bigger. Now they're tiny. 

#### Mike
I don't know how to fix that in Windows. I know how to fix that on a Mac. One of the reasons they may be tiny is how many of them do you have? 

#### Mary
The same amount is, I mean, it's the same thing every day, but this is the second time it's happened where they shrunk, but it's always been the same things on the press bar. 

#### Mike
Usually they're going to shrink if you have so many active things that they won't fit in the space available. They shrink the icons to make them fit in the space available. so do you have a lot of stuff pinned on the taskbar that you don't use 

#### Mary
I'm looking at no, no, no more. It was only two extra things and it's still tiny. 

#### Mike
so do you have a big gap between the right most icon and then the date time stuff on the right end 

#### Mary
um 

#### Mike
and don't worry about it it's a Windows thing 

#### Mary
okay you said the erd uh svg 

#### Mike
I don't know how to fix it yes 

#### Mary
okay you said look at it and 

#### Mary
You said to look at it and do what again? 

#### Mike
I want you to look at it, and I want to look at the customer journey and the coordinator journey sections. 

#### Mary
Okay. 

#### Mike
Thank you. 

#### Mary
Okay, the customer journey. Because there's one for coordinator, mentee, mentor. or the customer journey dashboard, subscription card. 

#### Mike
Okay, so we're going to drop card. We're not going to use it anymore. We're going to drop the dashboard. That's a fancy feature we're not going to do in the MVP. The subscription is going to move into the customer. 

#### Mary
I was going to screw it. 

#### Mike
And now all of a sudden, we don't have any collections for the customer journey. 

#### Mary
Right now they have subscription for customer journey. 

#### Mike
Right. 

#### Mary
So they can go. 

#### Mike
Well, we won't even have subscription. We will have moved the subscription data into the customer collection. 

#### Mary
So you want to have a need for customer journey. 

#### Mike
Right. You just caught up with what I was thinking. 

#### Mary
And. 

#### Mike
And we also have whatever it is that comes back from Stripe, whatever information we need for Stripe. 

#### Mary
Oh. 

#### Mike
Some of the information we need for Stripe, we're going to be able to put in the customer collection. But the data that's coming back from the webhooks, we're probably going to need a collection to store that. And so what I would propose is that we combine coordinator and customer. 

#### Mary
Thank you. Yeah. 

#### Mike
I'm really, I want to think about this hard. because this would delete an entire UI and API, the customer UI and API altogether. 

#### Mary
Mm-hmm. 

#### Mike
And the customer journey other than subscriptions 

#### Mary
Mm-hmm. 

#### Mike
is going to be read-only. So it can read anything from all the other things subscriptions are in customer transactions can be in that same journey I really want to reflect on this for a little while because this is a big decision 

#### Mary
Can I share my screen with you? 

#### Mike
sure 

#### Mary
Okay. 

#### Mary
Let me same page with you. How this, if you take away that, how this is, I mean, it's the same. This was probably never needed. It was just an extra area. You have your profile and branches off on that. Um. 

#### Mike
I'll tell you what, let me share my screen, and I'll make edits to the drawing. 

#### Mary
Yeah. Yeah. Okay. Okay. I couldn't figure out how to do the full screen. I just found it. 

#### Mike
Okay. This is, what's the Amazon identity service? 

#### Mary
- Pavenito. 

#### Mike
Cognito. This is Cognito. Also going to have some data out at Stripe. 

#### Mary
Okay. 

#### Mike
I want to put those, I'm going to get them way over here. do some rearranging okay we don't need dashboard we're going to add subscription to customer we don't need card but we do need type web hook data we're going to rename that something else when we can. 

#### Mary
Mm-hmm. 

#### Mike
I think we'll put that. We're going to do this to get around those arrows. 

#### Mary
Thank you. 

#### Mike
We're not going to have a customer journey. Get rid of these lines. let's make our customer journey background the same as the other journeys 

#### Mary
Shift everything a little bit. No. 

#### Mike
yeah I'm looking I don't really have room to shift things to the left 

#### Mary
Yeah. Because then you might as well just recreate the whole page. 

#### Mike
guess what I can do this 

#### Mary
Mm-hmm. 

#### Mike
What the heck? Quit messing with that one. 

#### Mary
Oh. and rotate 

#### Mike
Yeah. That's good enough. I'm not going to be super picky about that. And we don't need this word here because it's not like that. Okay. Amen. Profile is the most important one. Let's make it really big. 

#### Mary
Okay. 

#### Mike
Move our arrows. 

#### Mary
Um. You left out the O in Hook. I'll try not to say it. you 

#### Mike
Oh, it's all right. It's exactly what you're supposed to say. It's the kind of thing an engineer needs to look at. Thank you. Okay, this is actually going to make it easier. We're getting quite a few simplifications to our data structure here. Thank you. 

#### Mary
Hmm. 

#### Mike
Thank you. As you can tell, I'm obsessive about drawing pretty pictures. 

#### Mary
Yes. You know those little pointers, the. Arrowheads or whatever you call them. Those are tricky. 

#### Mike
Yeah, that's because they're not usual. Most people don't do that. I'm doing that to remind myself that a profile has a customer ID and a webhook response has a customer ID. And a profile has a Cognito account and a profile has a Stripe account. So there will be Cognito and Stripe information here. Here, a profile doesn't have links to notes, but a note was created by a profile. So a note will have a profile reference. See how those arrows go? So a journey will have a profile reference. 

#### Mary
Yeah. 

#### Mike
so yeah the arrows add a piece of information that's not normal in an ERD an ERD usually doesn't have those arrows but that's because an ERD is typically for a relational database and relational databases can only have relationships in one direction okay 

#### Mary
yeah almost i was just about to ask what was erd 

#### Mike
ERD stands for Entity Relationship Diagram. So we've got all of our entities, which in this case is all of our database collections. 

#### Mary
oh okay - Thank you. 

#### Mike
And these are the relationships between those collections. And relationships have a cardinality. So we've got zero or one relates to one. We've got many relate to one. So that's what those little symbols at the end of the lines. That's exactly one. That's exactly two. That's one. That's zero or one. 

#### Mary
okay Okay. 

#### Mike
That's zero or many. 

#### Mary
Okay. 

#### Mike
right? So each of those little symbols tells you about the relationship between these two objects. And the arrows tell me where the IDs are stored. So a rating stores a resource ID and a path stores a resource ID. and a resource is a one-to-one relationship with a resource aggregation. So it's one-to-one versus one-to-zero or more. 

#### Mary
Thank you. 

#### Mike
So I want to think about this for a little while because this is a really big change. 

#### Mary
You had froze for like one or two seconds. 

#### Mike
I really want to reflect on this for a little while. 

#### Mary
Okay. 

#### Mike
this is a huge change. 

#### Mary
Okay. 

#### Mike
We're dropping three tables and an API and an SPA. And I need to change this to customer slash coordinator. and yeah I really want to think about this for a little while I want to give my brain a chance to kind of ruminate on this 

#### Mary
Okay. 

#### Mike
because this is a really really really big change I would say for you, the most important research you can do is when we create that shopping cart with a subscription in it that we're going to forward to Stripe for payment. 

#### Mary
Mm-hmm. 

#### Mike
What does that data structure look like? What data do we need to send to Stripe with that call? When Stripe sends us webhook information to tell us something has happened in Stripe, payment has been processed, a payment has been denied, what types of events do they send to our webhook, 

#### Mary
Thanks. 

#### Mike
and what is the data structure of those events that it's sending to the webhook? Then we need to do the same thing for Cognito. What information do we need to send Cognito to create an account? What information do we need to send Cognito to update an account? And I think we've already got the stuff worked out about how I forward to a login page. I think that part for the UI is already done because we're forwarding to our own login page, our own mock login page. So I think that part of the Cognito stuff is done. What's not done is what information do I send Cognito to create an account? And what information do I send Cognito to update an account? So if you have that information, then we can make sure that the profile has all of the data it needs. And the Stripe integration can have all the data it needs. And what the data structure of the Stripe webhook is going to be. We need to look at customer and think about the information we need for a customer. We're going to have subscriptions in here. So it's going to be customer with an array of subscriptions, right? 

#### Mary
Yeah. 

#### Mike
So we need to kind of think about, we probably need to go in and add subscriptions to customer and really think about the customer data we need. I think we've got a name and a description. Do we need a shipping address? I don't know. It's worth thinking about. So that's where I would start, is let's find out about those integrations and what data we need for those integrations. 

#### Mary
Okay 

#### Mike
And then let's think about this UI. And I'm going to try and think, should this be the customer UI or the coordinator UI? Because we're eliminating a bunch of stuff. We're eliminating a whole user role. 

#### Mary
Okay 

#### Mike
By saying that the single user role can do all of the stuff that a customer can do, 

#### Mary
Okay 

#### Mike
which is basically just look at a dashboard and make subscriptions. 

#### Mary
Mm-hmm. 

#### Mike
Oh, no, we still do need that because we only want the customer doing subscriptions. The coordinator can't do subscriptions. So we still have the two roles, but we only have one UI and one API. And I think we're going to call it the coordinator. But that's not, it's really... I'm sorry. Yeah, let's ruminate on this and let you do your research. 

#### Mary
Okay. 

#### Mike
If you want to go in and manually delete those collections and add the subscription array to customer manually, you can. That puts you a step ahead. But I think you definitely need to do the rest of the research on Stripe. What information do we need to send Stripe for them to check out a customer and charge their credit card? And what information will Stripe send back to our webhook? Indicating what they've done. And you need to verify that workflow I was just talking about. On our customer UI, we're going to have a form that they fill out that is a shopping cart. This is what I'm buying. And we're going to send that shopping cart information to Stripe. So what does that information need to look like? And then we can make sure that we have all those data structures represented in our emails. Does that make sense? 

#### Mary
Yeah, it does. 

#### Mike
okay I'm going to think about this before so don't make any changes to the schemas yet 

#### Mary
Okay. 

#### Mike
yeah don't make any changes to the schemas yet I want to really really really think about this and we're going to make changing the schemas and updating the test data a ticket 

#### Mary
Okay. OK. There are two folders for MentorHub CraftsPerson API, 

#### Mary
and there's one for SPA. 

#### Mike
Where are you seeing these? 

#### Mary
There's nothing there. Can I show you on my end? 

#### Mike
Where are you seeing these? Yeah? You're already sharing your screen. 

#### Mary
Okay. Oh, I hit stop. 

#### Mike
Oh. 

#### Mary
Oh. Here. 

#### Mike
Oh, you can just remove those from the workspace. 

#### Mary
This too. 

#### Mike
You can just remove those from the workspace. Right-click on it. And remove from workspace. 

#### Mary
Oh, okay. because I didn't want to do anything. 

#### Mary
But that's been bothering me since yesterday. It was nothing there, and I didn't know if I should remove it. 

#### Mike
That's just... Yeah, you remember when we used to call mentee, coordinator, or craftsperson? 

#### Mary
Yeah. What happened? Do you recall the day that I said I couldn't get into Cursor? So instead of accidentally messing up, I clicked the button that says duplicate workspace. And I thought they put me where I was supposed to be. So that's why it looked like it did yesterday. 

#### Mike
No worries. 

#### Mary
I just want to explain it hard. 

#### Mike
No worries. All right. Yeah, why don't you write down those two pieces of research? So Stripe, verify the checkout workflow, and identify the information that goes both directions. Same thing as... 

#### Mary
I'm gonna I've seen them. Did you want me to type it there? 

#### Mike
Yeah. Yeah, Obsidian is a good place to keep track of it. 

#### Mary
Okay, so What was the first one? 

#### Mike
So the Stripe workflow. We have the shopping cart. We forward to them for checkout. Right? 

#### Mary
Oh, yeah. 

#### Mike
So verify. 

#### Mary
Is it easier if you feel like it to send me the. Whisper transcripts of today's station. 

#### Mike
Sure. 

#### Mary
Because I want to go through everything that you said and put all of the research into Obsidian. 

#### Mike
Okay. So put all of the research in research markdown files in the MentorHub research folder. 

#### Mary
If that's OK with you. 

#### Mike
If it's in Obsidian, nobody else has access to it. 

#### Mary
Okay. 

#### Mike
I want everybody to have access to it. 

#### Mary
Okay. Okay. 

#### Mike
Oh. 

#### Mary
I was meaning to put there to everything we talked about, and I was going to go back into it to see what I can do step by step, everything that you are asking for. 

#### Mike
Okay. You can put a task list in Cursor that says, I need to do these things. 

#### Mary
Yeah. 

#### Mike
So the things that you need to do are you need to confirm what the Stripe workflow is. 

#### Mary
Yeah. 

#### Mike
We have a page where they create a shopping cart, and then we forward to their page for checkout. So I want you to confirm that that's how that is supposed to work and identify what information do we have to send them in order to check out. 

#### Mary
Okay. 

#### Mike
And I want you to also look at Stripe and say, what information do they send back to us through webhooks? I believe it's going to be payment processed or payment rejected. I really think those are the only things we'll get back on a webhook. 

#### Mary
Yeah. 

#### Mike
Okay. If when you're identifying the stuff that we need to send to Stripe, you identify things that need to be configured in Stripe, for example, a product and a price or whatever those things are, we probably need to understand that as well. 

#### Mary
Mm-hmm. 

#### Mike
Because I do think we're going to have, I just realized we are going to have probably another collection related to Stripe. And that is going to be... We're going to have product... Yes, a product is going to be referenced from a customer in the subscription. So they'll have many subscriptions referencing many products. Okay. Let's give ourselves a little more room here. me obsessing about pretty pictures again. 

#### Mary
No, I am the same way. If it looks off, I will. If it can be fixed, I'll fix it. 

#### Mary
If it can't be fixed, start over. 

#### Mike
What the heck? 

#### Mary
Oh, yeah, I was just about to. I'm glad you said it for me. 

#### Mary
That is crazy. You have the whole page, Mr Mike. 

#### Mike
Thank you. Yeah, let me think about this for a little while. 

#### Mary
Okay. 

#### Mike
Do you understand what product is? 

#### Mary
Okay. 

#### Mike
Yeah, product is the thing with the price. It's a subscription, maybe a subscription type. So we might have partner subscriptions versus third-party subscriptions versus individual subscriptions that each have a different price. 

#### Mary
Yeah. 

#### Mike
So, yeah, be thinking about what our products are, how we're going to price it, the information we need to send back and forth to Stripe, the information that we need to send back and forth to Cognito. So, those are what's going to define the data schemas that we're going to be creating. Make sense? Oh, beautiful. 

#### Mary
Yeah. 

#### Mike
They did cut them down, and they cut that one down almost. It's sort of got to fall over still. Oh, dude. 

#### Mary
Just a little push. Just a little push. 

#### Mike
Yeah. You wouldn't believe how much better. Oh, there it goes. There it goes. They're cutting it down. You wouldn't believe how much better my view is going to be. You wouldn't believe. It's. 

#### Mary
So is that going to help you not being a funk every day? 

#### Mike
My funks. 

#### Mary
It's not the major things, the little things that makes us happy. 

#### Mike
It is My funk has to do with bipolar and chemical imbalances in my brain. So yeah, this will help because it's pretty. But I don't expect it to have any major outcomes. Does that mean they're going to cut those down too? Oh, these people are risking a lot, a lot, a lot. Because now I'm looking at counting. They've cut down almost a dozen trees on city property. 

#### Mary
Oh. Oh yeah, this is not gonna go unnoticed. 

#### Mike
so the reason the city owns this property is because it's too steep to build on when I say I'm on the top of a mountain I mean I'm on the top of a mountain and the land below me is so steep that they couldn't build on it So they made it like a park that you could walk a trail on. But it's such a short trail and such a steep trail that nobody ever walks on it. So I'm actually kind of excited. Okay, I'll send you a transcript. You've got the to-do tasks. 

#### Mary
Mm-hmm. 

#### Mike
Let me know if you have any questions. Let me know what you find out. Because, like I said, this Stripe and Cognito research is super critical to the database because we have to know what information we store to send to those integrations. And we have to know what information we get back from those integrations. 

#### Mary
Okay. 

#### Mike
For now, don't worry about anything but the data structures and the workflow. All right? 

#### Mary
okay 

#### Mike
All right, I'll quit making assignments. 

#### Mary
no continue 

#### Mike
No, I've made too many. All right, I'll send you a transcript. 

#### Mary
okay thank you and I will break it down um and put into I mean I'm going to take the whole transcript and place it into Obsidian. 

#### Mike
I'll send you the whole Obsidian doc. 

#### Mary
And then from there, I would... 

#### Mike
Just copy that markdown file I give you into your Obsidian folder, and you should be able to open it then. 

#### Mary
Okay. Cool. 

#### Mike
All right. Talk to you soon. 

#### Mary
Okay. Peace. 

