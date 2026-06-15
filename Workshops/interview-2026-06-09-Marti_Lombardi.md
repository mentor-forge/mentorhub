# Interview - Marti the Mentor
- Introductions
- Define Scope (her work as a mentor)
- Does, Says, Thinks, Feels
- Meaningful Outcomes
    - What does mentorhub HAVE to do on the first day
    - What could prevent you from using the system
    - What would make you say "WOW" when learning the system
- Questions from the team

## Summary from gpt-oss:120b
**TL;DR** – Marti needs a flexible, low‑maintenance Mentor Hub that lets her capture personal notes, track mentee progress on learning journeys, and surface alerts or summaries without forcing extra data entry.

**Brief meeting summary**  
The conversation centered on Marti’s extensive experience as a mentor and the challenges she faces keeping up with rapidly changing technology, diverse mentee goals, and the administrative overhead of tracking progress. She described her current workflow (mostly Excel/Word notes, occasional Google Drive files) and highlighted the need for a system that is simple, respects privacy, and adapts to each mentee’s evolving career path. The team clarified that the upcoming Mentor Hub will replace spreadsheets, provide a dashboard for mentors, and record resource usage automatically. Marti emphasized that the tool must be unobtrusive, flexible, and give her quick insight into what each mentee has completed, what they’re struggling with, and any life events that might affect their learning schedule.

**Key UI design requirements**

- **Clean, single‑page dashboard** – a high‑level view showing all current mentees, status icons (on‑track, at‑risk, paused) and quick‑access to individual profiles.  
- **Minimal manual entry** – most actions (starting a resource, marking it complete, adding a short note) should be a one‑click or auto‑captured event; avoid long forms.  
- **Personal notes area** – a private, searchable notebook for each mentee where Marti can type free‑form observations (e.g., “Andrew was depressed last month”). This should be separate from the structured progress data.  
- **Progress timeline / learning journey** – visual representation (e.g., a vertical list or progress bar) of assigned resources, completed items, and pending modules, with the ability to add ad‑hoc resources (YouTube, external courses).  
- **Alert/notification system** – subtle flags when a mentee hasn’t logged activity for a configurable period, or when a deadline is missed, so Marti can prepare talking points before meetings.  
- **Privacy controls** – Marti’s personal notes stay private; mentee‑visible data (completed courses, badges) can be shared with paying customers but not with other mentors unless explicitly allowed.  
- **Responsive design** – works on desktop and tablet, because Marti currently uses a laptop for notes but sometimes reviews on a tablet during meetings.  
- **Export/backup option** – ability to download notes or progress reports as CSV/Word for offline archiving or compliance.  
- **Flexibility for life‑event tracking** – a simple field or tag to note major life events (e.g., relocation, military service, health issues) that can influence learning plans without cluttering the UI.  
- **Search & filter** – quick search by mentee name, skill area, or status, and filters to show only those needing attention.  

These UI elements aim to give Marti the “glance overview” she described while keeping the system light enough that she won’t view it as extra work.

## Transcript
#### Marti
new? What challenges do you have? Mike initially on a spreadsheet set up a base list of questions 

#### Mike
So, let's go. 

#### Marti
that were good for guidance, but that evolves over time. I've been working with one of these gentlemen for two years now, I think, and I was meeting with him weekly, but he was answering a lot of his own questions and taking his own strategy after two years. So now we still meet monthly, but I think it's more because I don't want to lose touch with them. I just enjoy talking with them so much. I've had some that were short-term. One individual, she got a job, 

#### Mike
Thank you. 

#### Marti
I think, within three or four months of my starting with her. And she did really well, and she was completely changing careers. She wanted to go technical or IT because I'm a musician, but she was a music teacher and also church choir director. And she discovered, as I learned, like when I was in high school, there's really no money in music. So I've had also some friends, Mike and I worked with a gal by name of Alison Ferguson at Candle and then at IBM. And Alison was a great photographer. But she said, but there's no money in it. You know, so there were things like this where you have to decide, you know, what your life is going to be like. 

#### Mike
Yeah. 

#### Marti
And that's what I tried to listen to and answer some questions. There's even times I've said to Andrew, are you OK? Do you still want to continue meeting with me? And he said, yeah, I like to bounce ideas off of you. So he, you know, that's kind of where we're at. But I felt that, and I got this from the training session Mike had put me in three years ago, that listening is just really important and not making assumptions and asking the right questions. Now, how that transfers to what you want to do with a technical hub for learning, I'm not real sure. But certainly, and if you guys are watching this in the news, it's just changing daily what we want to get them enabled on to help them grow. You know, it just it seems like everyone's got a new idea, you know, every month or every week. And I still find AI confusing, guys, personally, because I've not read a lot about how they are effectively using it. I'm just seeing a lot of comments like, oh, I want you to have a year in AI or two years in AI. I even saw someone comment that they want you to have five years in AI, and it's like, no, it wasn't there. Give me a break. 

#### Mike
Yeah. 

#### Marti
So, you know, they're written by some HR person who doesn't understand it. Or Mike likes that, you know, software as a service and it's friends, you know, PAS and ISA, you know, integration. 

#### Mike
Yeah. 

#### Marti
Yeah, they say we want you have 20 years. And I said the cloud wasn't even there. It's a cloud based technology. ISDM at IBM really evolved in 2011 and 2012. So, you know, and then everyone else, you know, Amazon, everyone jumped on the cloud bandwagon, which was good. because smartphones needed them. And it was the smartphone growth that really demanded it. 

#### Mike
Good. 

#### Marti
But I think, you know, even after 12 years, a lot of people don't even understand cloud and what SaaS is. So I think our challenge is trying to determine in a moving global market, what do they need? And then how do you adapt to it? Because as you create these training hubs, You know, some new important thing may come out a month or two months from now. And we're going to want to look at whether or not it's something that makes sense for them to learn. Like one of the databases like Mongo or something. Well, that's now bigger, been around longer, but these things are going to evolve. 

#### Mike
Thank you. 

#### Marti
And how do you code quickly, but not necessarily quickly, but the word I want to use is a business word, which is agile. I remember years ago, you guys, I don't know if you're old enough to remember this, but I had MCI, and they were bought by WorldCom, and I forget. They were now the smart telephone, but they were wrapped into Verizon, I think, eventually. But that company told me when they were a candle customer, Mike, they said, we have these commercials that say, you know, talk about AT&T versus us versus what was in Sprint all the time. 

#### Mike
So, let's go. 

#### Marti
So you know that we can't wait for Y2K, which was being discussed a lot then, or we can't wait for technology to change because we're in a competitive nightmare every day. So I wish people would quit talking to us about where do you want to be five years from now? 

#### Mike
Thank you. 

#### Marti
We want to survive is what they would tell us. So, and then our question was, how do we produce the solutions that helps them survive and keeps them up and running and monitoring as we were a candle? So, it's just all changing constantly. And how my concern is how we adapt. 

#### Mike
Okay. 

#### Marti
And if they ever figure out what AI really is good at, you know, there are some things I can think of. But that's all based on my subjective. Like when I was a product manager, I used to write painstaking deliberate long scenarios on what Candle Command Center for CICS integrated with DB2 was going to do for a bank that was in a merger. It took me forever to write that stuff. And if I had AI, it's possible that I could have written it much more quickly or put into Here's the scenario I'm envisioning. There are uses for it, but I'm afraid everyone's just saying AI. And now we're trying to figure out how to present that to other people. 

#### Mike
Yeah. 

#### Marti
So the big things I see is asking them the right questions, getting them on the right path, getting them the right content. And then are they even interested in the content? Or are they just saying, oh, you know, I don't know what I want to do when I'm out of college. Or in the case of the Persevere guys, you know, Mike, you know, when I'm released from prison, for like a better word, but I want to start my next life, what is it I need to know and how can I be the most useful? 

#### Mike
I'm... 

#### Marti
And they're going to have to understand it's going to evolve. And then how do we present that? That was a lot of rambling. 

#### Mike
I think it was very, very helpful. I think that the people here on the call already have a better idea for why you're a mentor and your experience as a mentor. 

#### Marti
Yeah. 

#### Mike
I think you were highlighting a key pain point, which is the lifelong learning aspect of this. I think one of the things that we have kind of documented is that the idea of lifelong learning is not just the mentee or the apprentice. It's also the mentor. I mean, I've had to learn a lot of things, new things, to be able to be a mentor. 

#### Mike
Thank you. 

#### Mike
And you kind of highlighted that problem of there's always new stuff coming out. How do we know what new stuff to do? And so it's a learning journey for us as well, isn't it? 

#### Marti
Well, it's changed so much for us. A new release of a mainframe or a mainframe subsystem, like a database, they put years into it. So all of a sudden, we're doing these short sprints where they're putting things out within a couple months for competitive reasons, guys, a lot of times. 

#### Mike
Yeah. 

#### Marti
All these little software companies have to work much more quickly. And then our goal is, okay, is this something they really should learn right away? 

#### Mike
Mm-hmm. 

#### Marti
Is this something interesting? What's the market? What's the plan? 

#### Marti
And then you can't make that decision right away because you don't want to waste their time or mine. But, you know, it's... 

#### Mike
So I'm really looking forward to showing you what we're building and how that's shaping out. And I will definitely follow up with you on that. If you don't mind, what I would like to do now is I'd like to kind of set the table a little bit in terms of the scope of what we want to discuss in detail. And that is I really want to focus in on your experience as a mentor and the encounter where you're talking to a mentee, what that workflow is like for you. So if you don't mind, when you're mentoring somebody, can you walk us through the things that you do while you're setting up, preparing for that encounter? You have that encounter. Maybe you do something right afterwards, take some notes or whatever. Can you describe what you do in that process? 

#### Marti
I take a lot of notes so that I remember especially 

#### Marti
well like with Andrew I'm meeting him once a month but I want to remember what we talked about I mean you know technically I kind of remember but there may be some specific details he wants to do the cyber security field so he does some conferences sometimes he was interviewed for an article so what we kind of do is say since the last time we met what activities have you done and you know, how does that help you long term? And why did you choose to do it? 

#### Mike
Thank you. 

#### Marti
He's also got some life decisions going on. And then, you know, if you've got life decisions going on, that affects everything else. So he tends to not want to drop the ball on both his career goals. But at the same time, you know, he strategically may be looking at moving into his grandfather's place or his grandfather's house and then in order to do that he'll have to pay some things 

#### Mike
Thank you. 

#### Marti
so then is the job he has a target, is that good enough also he's looked at internships but they don't pay so they're going to help him grow but at the same time he needs to have money he doesn't have a car yet so if he does he's going to have to have insurance You know, so all these things. So he's making the debate about the financial versus the growth and how do we merge them together successfully. He works very hard at school. He's, you know, mostly A's, maybe a few B's. He wants to get done quicker. You know, like a lot of us, we want to be at that future we envision two, three years down the road. So how does he get there? So that's part of the discussion. Initially, when I first met him, he envisioned being in Germany in a few years because his grandparents were German and he was learning German. Actually, I think he's had a course in school in German. I found it a very difficult language personally. Maybe it's good for technical people because the Germans are very technical. Having been there a lot, they do the BMWs, the Mercedes, the Deutsche Telekom, Dresdner Bank. I'm thinking of places I had visited over the years. 

#### Mike
Thank you. 

#### Marti
But they really, you know, he looked at it and said, well, you know, his dad had been ill and then he lost his grandmother and his grandfather. is not well. So he started thinking maybe long term, but I'm not going to do it now. But he's actually researched that a lot. You know, there's a lot of things that we know that they will plan and want to do. 

#### Mike
Thank you. 

#### Marti
Same time, they also life, I don't want to say life interferes, but life comes. It's not an interference, but it's still part of my long-term plan, but I've discovered the best way to get there is through that. Another thing he looked at is the military, just to show you how his mind has processed how to pay for things. Because he realized if he was in the military, he might get some financial assistance. 

#### Mike
Education. 

#### Marti
So that's important to a lot of people. And all these things come up in every one of our discussions, you know, each time we meet. 

#### Mike
And it's amazing how some of the agile principles of being willing to adapt to change instead of sticking to a detailed plan, they apply to life's lessons as well as they do to technology. And so I think that's an important point that you do act kind of as a life coach in some capacity because of the commonality and the techniques we use to manage our work and how they can be applied to life lessons. I think that's really good. It gave me a better picture of what you're doing. So how do you take notes? Do you take notes on paper or do you use obsidian or? Yeah. 

#### Marti
I don't even know what that is. But I use my old tools, Mike, for now. I use Excel. And then when I couldn't find my old copy, I went to Word. 

#### Mike
Thank you. 

#### Marti
But I usually keep it in a corner and I do some typing while he's talking to me. And I'm using him as an example. I also did it with Parth and I did it with Laura. And I think that it's just a really good idea to be able to refer to something. Because as an example, he told me he was giving an interview for a newspaper. Then on LinkedIn, he posted the interview. And I went back and I said, you told me it was going to happen. I saw it in the notes. And then I went back and you did it. And he talked a lot about it. So I think that this is something that interests him. And that one specifically was about the conference. It might have been B-side, but it was specifically about the cybersecurity conference and his participation. 

#### Mike
Mm-hmm. 

#### Marti
And, you know, he works as a team. And then the team, you know, gets rated on their contribution. 

#### Mike
Yeah, it's, yeah. 

#### Marti
So there's just a lot of things that he's done. 

#### Mike
And I want to make sure everybody noticed how invested Marti is in her mentee and his life. 

#### Mike
Yeah. 

#### Mike
It's not just an hour a week or in this case, an hour a month. There's some real investment there. So, Marti, when we think about the process of working with somebody and mentoring somebody, when you're thinking about that, what are the things that come across your mind when you think about mentoring? 

#### Mike
Thank you. 

#### Mike
I mean, you've covered a lot of it, but if you could just summarize, these are the things I'm primarily thinking about. I think the first thing you said was the most important thing is to pay attention to the person in front of you. Continue along that line. 

#### Marti
I think your word invested is what's important. Yeah, I'm invested, but obviously you want to show them that you care, and you want to be able to give them time to talk. And I'll tell you, as a teacher, Mike, when we did live classes, there aren't a lot of those much anymore because they don't scale. You know, you got to fly somewhere and sometimes those people fly to me. 

#### Mike
Yeah. 

#### Marti
You know, they don't scale. I still like conferences. But when I was a live teacher, I used to get a flip chart and I would go around the room and I would have everybody introduce themselves. And then say, what is one thing you really want to leave with when you depart this class? And then I put it on the flip chart. And then as we got nearer the last day, I would start checking things off to make sure that we had answered everything they came to hear. I didn't care if that going around the room took us up to the first break. I just wanted them to talk about why they were there. And I think that that initial, I learned later, I thought about it. It wasn't just making sure you covered the main points. It was listening. It was talking to them. It's really boring for people to just sit there for three and a half, four days and listen to someone just talk. You know, that's one of the reasons why labs and other things are very important. But if you start them with the introduction, it's important. I did have, I thought this was funny, one time, I think it was an on-site class, I think in Omaha or somewhere, an insurance company or a bank. But I was asking everybody, like, I think there were some operators there, some system programmers. And when I started to ask the operators while they were there, the system programmer tried to interrupt and say, I can tell you why they're all here. And then he gave me the answer. And I was like, that's really nice. Okay, next operator. 

#### Mike
Thank you. 

#### Marti
I don't know if he thought he was trying to help and thought they wouldn't know. But if they didn't know the answer to the question, I needed to know that. So that's some of the things that you kind of work through in dealing with people. And that's why sometimes one-on-one is a little better than group, unless it's a small group and you're handling specific topics. 

#### Mike
Okay. 

#### Marti
maybe two or three, but it's important to get them to listen and you to listen and for them to talk, even if you have to interrupt someone who's trying to help and say, oh, that's nice. Okay. That's the type of thing that you need to start with is getting down to, are you here for a reason or are you here because you have a manager who just said, go to this class? 

#### Marti
And if that's the case, that's also something else I needed to know. Again, it's all communication. 

#### Mike
Paying attention to the person in front of you. We seem to be coming back to that quite a bit. I think that's really clear. 

#### Marti
yeah 

#### Mike
So let's talk a little bit about resources. So the learning resources, the classes and things like that that you've shared with your mentees. Where do those come from? How do you organize them? What have you been doing in that space? 

#### Marti
I will sometimes use Google to find something 

#### Marti
But if it's not something on the portals here that you have, or if it's something that's not technical, I'll go outside. I'll look at YouTube. Perfect example. Part. I think it's currently still in India. But, you know, he was working in Canada. His visa time expired. He visited the U.S. And now he's back in India until he's able to get back to this bank in Canada that he had been working with. But if you know these lovely, wonderful, smart guys from India, they have one challenge. And he recognized it early. 

#### Mike
Mm. 

#### Marti
I want to be an executive. 

#### Mike
Mm. 

#### Marti
That means I need to learn how to talk at a better pace to deal with them. 

#### Mike
Mm-hmm. 

#### Marti
And, you know, there are times you sit there on the phone and go, you know, I know they're speaking English, and I think they actually were raised speaking mostly English, but I don't understand them at all. And it's the speed at which they communicate. So he said, I understand all these classes. And he would do the classes that Mike and the team had organized. And he would learn something and sometimes he'd skip certain segments that didn't interest in him, but there was plenty of other things to look at and skip ahead to. But when it came to learning to speak, we looked at things he could do. We looked at books he might acquire, but more I felt he needed to watch something. So we looked at YouTube videos and learning how to slow down and talk. And then another idea we looked at was Toastmasters. 

#### Mike
Yeah. 

#### Marti
So those are some of the things that would help solve the problem he had that was more a what's out there, what will get you ahead, that wasn't on things like a technical hub. 

#### Mike
Yeah. Yeah. Okay. 

#### Marti
So that was some of the things. And in the first case with Laura, she worked through a lot of the things that you had outlaid, too, on the technical hub and the courses. 

#### Mike
Okay. So when Marti says the technical hub, she's referring to primarily the curriculum documents that I have shared with y'all. 

#### Marti
Yeah, I'm sorry. 

#### Mike
So yeah, those curriculum documents have been kind of our primary list of resources right now. So I think that's what she's referring to. So, Marti, if we wanted you to sign up for and use this new Mentor Hub platform so that we could track the progress of your mentees and help report, you know, one of our ideas is that we're going to be able to sell mentorship services and be able to use that revenue to compensate mentors. And to run the platform and pay the software engineers that are running the platform and managing things. And so, obviously, if we have customers that are paying, they're going to want to know the status of the people that they're paying to be mentored. And the progress and how things are going there. And so, we've got a whole thing about the relationship with the customer. But part of that is knowing where things are at in progress. So if we were to ask you to use the Mentor Hub system to take your notes during your meetings and help report when you're meeting with the apprentice, that's the way we see you using the system primarily. And in that case, we have some requirements for the customer and other things. But for you as a mentor, what does the mentor hub platform absolutely have to do on day one for you to even find any value in it? 

#### Marti
well first of all I would use it for a lot of reasons 

#### Marti
first of all what you said to I don't want to say justify your existence but make sure that they can track I do have like minor concerns about the privacy but some of the things they might say I'm thinking of day when Andrew was particularly depressed and then I wrote it to my own notes so maybe I should keep my own notes and I may have notes but I think that a mentor hub with notes is needed to some degree not just because of the business reasons you raise on the people paying for it but because I hate to say if something happens to me if I get you know knocked over by a drunk drunk driver on 

#### Mike
Hmm. Nuity. 

#### Marti
i70 you know how do you pick up how do you know what was going on um and you know we were using a google drive but that's not absolute and so for and of course you wouldn't want to give all these other people access for all the documents on the google drive so i think that i would use it and that's why I would use it. What I would want to be able to track and put in there is what the, you know, some nerd notes, obviously some anecdotal notes of the meetings, but I think it absolutely has to have a good understanding of what training 

#### Mike
So, let's go. 

#### Marti
they have completed that you can track. you know stuff like on YouTube or other things yeah that you you're not gonna be able to track at all but um hopefully we can make notes about that but that is a challenge I had when like Parth would say oh I worked on this course and I would say well did you finish it now I'm mostly done I really would not understand how far he got and then of course my question back as a mentor was, okay, you got this far, but how is it helping you? 

#### Mike
Mm-hmm. 

#### Marti
What were you able to do it? How did you apply it in your day-to-day work or even just once a week? How did you apply it? Those type of questions. But it's easier to ask those questions if you know what they have specifically accomplished from a training perspective. So if possible, I'd like to see the ability to track and then merge it in to whatever profile we create. Believe it or not, when I left IBM, that's what they were doing with partners. If you think about it, what we were trying to do was measure what courses they were taking, what credentials they had earned, a badge or a certification. 

#### Mike
Go files. Thank you. 

#### Marti
And then we were looking at their pipe and revenue and trying to put it all together. And, you know, was it working or not working? Were there classes on data security that they were techie? And did it help with those solutions or identity and access or system security information event management, which I call a SIEM? I'm talking like the security portfolio, because that's what I've worked on. when I left. We needed to know if 

#### Marti
that power up. 

#### Mike
Headphones went dead. 

#### Marti
I don't know what happened. We needed to know if what we were creating was working. 

#### Mike
Go. 

#### Marti
You want to know if what you're creating is working. If it's worth spending time on. If the time was valued. because you have so many millions of dollars that you've got unlimited budget to create stuff, right? So you need to know with the resources you have what's working. So, like I said, we were tracking partners and regions. And to my surprise, Europe, Middle East, Africa had a much better, stronger content usage. And even revenue and pipe, except North America did. And I just thought, well, why is this? Well, North America, you have a lot more direct sellers. Maybe that was it. But even after in Europe, and I remembered this vividly in 2022, even after we had to pull Russia and Belarus out of their pipe and revenue, they still were kicking North America's ass. So, you know, so we always track that. I want to know what they're consuming so that I can discuss it with you. I see you completed this course. That's really great. Do you have an immediate need for it or do you want to start another course? Or why did you find this one interesting? Those are very important questions about how you direct their future. 

#### Mike
So let's imagine that we've got this mentor hub system. What can it not do? What would make you just absolutely hate using it? Pet peeves. 

#### Mike
I'm thinking if it was really, really tedious, really time consuming, I don't even mind time. 

#### Marti
I think tedious is probably a better word. If it was, you know, difficult to manage or learn. 

#### Mike
okay so 

#### Marti
But at the same time, I recognize that if people are paying you to do something, they're going to want features. And just when you think you've got it figured out, as they start using it three months from now, they're going to say, you know, it's a product manager, Mike, right? 

#### Mike
Yeah. 

#### Marti
Two months from now, they're going to say, oh, wow, this was really great. But if you could add these two things and then three months later, they're going to want you to add two more things. 

#### Mike
If it's just two things and if it's three months between, that's not bad. 

#### Marti
So it's going to be perpetual. 

#### Mike
In my experience, it's at least half a dozen things every week. 

#### Mike
Yeah. 

#### Mike
So, yeah, being agile is super important. 

#### Mike
It could be. 

#### Mike
That's why we had to learn to be agile is so we could go with that pace. Um. 

#### Marti
I think you've probably already done this, but you probably need the people who are paying, you probably need like a mini advisory council to say, you know, how I'm thinking of when I ran them as a product manager, but, you know, what would work for you? And, you know, here's a prototype and then kind of go from there. But I can't think of something that would really hate me, hate, me hate to use it outside of it just being very wordy and very tedious because they want a novel every week on the conversations. 

#### Marti
But I don't think they're going to want that 

#### Mike
Okay. 

#### Marti
because I don't know that they're going to have the time to do that, to read to that level. 

#### Mike
Okay. Wow. Okay. I have one last question, and then I'm going to open it up for questions from the rest of the team. But if you could think of just magical things, what would really wow you if you got into MentorHub and it just made you drop your jaw? What kind of thing would be a big wow for you? 

#### Mike
A dashboard that, yeah. 

#### Mike
Okay, the dashboard of your mentees. 

#### Marti
Right, a dashboard of who I'm mentoring, information that maybe I have access to that not everybody does, but it doesn't matter if I could see names here and I could pick on the name. And even a status. You know, like they said that they would complete this course this week, but they didn't. Is that like a little bit of a yellow? Do you want to follow up on it? Could be personal. Things happen. I might be evacuating a wildfire in the next couple of days. You can probably hear the wind outside. We're in severe fire danger the next couple of days, and the wind is just nuts. You just, things happen. I actually do have the dog stuff all packed and ready to go. 

#### Mike
Oh. 

#### Marti
I do. I do, because I came up from Denver in the weekend, and I still, I have everything but their medications in one location to grab. But it, and I've had to do this before, sadly, 

#### Mike
Mm. 

#### Marti
if you can believe that. But, you know, any things happen. So maybe they didn't get to it for a reason. So, but then maybe you get like a little pop-up alert or a little thing on the dashboard that said, oh, they said they do this last week, but they didn't. They didn't have time. Maybe they did one module, that's okay. I'm not on a time constraint if they aren't, if something 

#### Marti
happened. We just have to work through the process. But it would be nice to know that information before I meet with them. 

#### Mike
Okay. Sounds good. So I think this has been very helpful today. I really appreciate your time. Let me kind of go around the table and see if anybody has any questions, because I'm sure they've been listening as interested as I have been. 

#### Marti
so 

#### Mike
So let's start with Mary. Do you have any additional questions for Marti? 

#### Mary
when made you i'm trying to trying to put into uh i want to ask the question What inspired you to become a mentor? 

#### Mike
What inspired you to become a mentor? 

#### Marti
Oh. I'm sorry. No, it's okay. That's fine. When I was, well, soon after I left IBM and I wanted something to do, and Mike came to me and thought about it, looked over the materials, and I actually enjoyed it quite a bit. I'm an oldest child of six. Unfortunately, we've lost my younger sister. But, you know, went through a lot and did a lot more caring, you know, than maybe I should have. But I just feel there's not enough compassion right now in the world. And if I listen to the, a lot of times I can't even listen to the news much anymore. So I feel like there's a lot of opportunity and underserved communities are just so not getting the focus they need with some very, very bright people. You know, one of the things Andrew and I talked about was the moon, you know, Artemis, Artemis II. And that is just so inspiring. And a lot of us just don't understand what it takes to get there with these really, really bright people. And I think that I would like to see more people realize that they have those skills. Now, another thing I'll tell you, and this is kind of a personal story, because of the way I was raised and my dad was a pastor. 

#### Mike
Thank you. 

#### Marti
and my mom was a music teacher and dad was also a musician. But I really did not take well to school. And then all of a sudden, in 11th grade, two things happened. I scored second in the school math contest, which shocked everybody, including me. And then when I had my SATs, I scored 730 in math, which shocked everybody, including me. And it was like, the teachers were like, you know, you're actually pretty bright. And I said, yeah, just don't put me back in biology. I hated that. In fact, because I love animals, a lot of people said you should have been a veterinarian. I said, no, I almost flunked 10th grade biology. It wasn't my skill, but thank you. So it's understanding those skills. So being able to share that story a couple times has also kind of helped. And it was like, well, darn, she's actually not half bad at this stuff. So accounting was very easy. I don't consider accounting real math. I just consider it debits and credits. And I was an accounting major and a business major and a comp sci major. I did a triple major in college. and I went through it in three years so it's like I kind of just shifted you know it doesn't mean I don't still love music but it just 

#### Mike
Thank you. 

#### Marti
was not going to cut it for what I wanted to do and I just figured a lot of people had similar stories out there 

#### Mike
All right. So let's see. Lucky, do you have any questions for us today? We've talked about quite a bit. 

#### Marti
so 

#### Lucky
Yes, I was thinking that this app that we're building in this situation is going to be kind of like your personal assistant, right? So what would you need in a personal assistant for you to stay interested in continuing working with this as a personal assistant? You know what I'm saying? What would you be looking for as far as keeping your interest in mentoring in general? What would this app need to help you do that? 

#### Marti
I think it's going to have to evolve as a personal assistant. But one thing that occurs to me is it's going to have to be flexible. And maybe that's part of the evolution because things will change. And I learned a lot doing this. You know, what I envisioned when I started working with Andrew and Laura, my first ones two years ago, what I envisioned ended up, you know, it still ended up very positive, but there were some changes along the way. 

#### Mike
Mm-hmm. 

#### Marti
So I wanted to be able to, you know, be flexible enough. And I know that's kind of a challenge for you guys, because other than saying, well, this week exists and this week exists and it's just being a narrative. It's hard to kind of get it going. And we may have to play around with it as we go. But I just want it to not be narrow where the only thing that attracts is, oh, my weekly or whatever narrative plus, you know, what they're learning. 

#### Mike
Mm. 

#### Marti
you know we may need to add some things to it we may need to have certain things like what are their life goals like I said two years ago Andrews was to eventually end up in Germany not you know and everything was focused on that and how did he get the skills to have a job to end up in Germany as an engineer 

#### Mike
All right. 

#### Marti
where now it's mostly cyber security and it's here right now he's focused on trying to work for L3 Harris, you know, trying to get inroads in there. 

#### Mike
All right. 

#### Marti
So how, you know, and he may still have that other goal, but he's got interim goals now. So how do we track it? And then at the same time, if it doesn't look like they're quote on track, how do we decide if that's really a bad thing? You know, I still think the mentor needs to understand and get an alert, 

#### Mike
Right. 

#### Marti
but it may not, things are going to happen. So it may not be a bad thing. It's just an opportunity for discussion. 

#### Mike
Right, right. 

#### Marti
So I want it, I just want it to be flexible enough to understand what he's doing. Do you, and maybe this is a question for you, Do you envision them at all entering things that are picked up by MentorHub? 

#### Mike
So where we've been currently using Google Docs or Excel spreadsheets, we envision those going away. And so instead of going into a Google Doc that has a curriculum, they would log into the portal and see those resources on their curriculum in the Mentor Hub portal. 

#### Marti
Okay. 

#### Mike
And then when they click a link to go visit a resource, we can record that in the system to say, hey, they started this thing at this point in time. 

#### Marti
Thank you. 

#### Mike
And then when they're finished working on it, they can go and flag and say, we finished it and leave notes or ratings or those types of things about the resource. So we are envisioning that on the mentee side of things that they would have the equivalent of a curriculum. I think we're calling it a learning journey. And, you know, you would help put resources on their learning journey and then they would mark them off when they completed them. So we do have that kind of progress mechanism in here as well. 

#### Mike
Okay. Okay. Okay. I'm just thinking of everything in one place. 

#### Mike
Yep. 

#### Marti
Like a central point of control, like we used to talk about when we were a candle. But, you know, it's important to be able to get a quick, you know, a glance. 

#### Mike
Yep. a glance overview 

#### Marti
Maybe a glance overview. Maybe how we interpret it will vary depending on the individual. But a glance overview would be, you know, helpful between, you know, what they're doing and, you know, what they get to enter. 

#### Mike
right okay 

#### Marti
and, you know, 

#### Mike
keep track without asking them to enter a lot of stuff 

#### Marti
you know, what we get to end. 

#### Mike
right yeah 

#### Marti
Well, yeah, don't ask them to enter too much. 

#### Mike
alright 

#### Marti
They won't. 

#### Mike
yeah 

#### Marti
That becomes a task and not a 

#### Mike
not a tool 

#### Marti
aid. Yeah. 

#### Mike
yep alright so Daniel do you have any questions for Marti 

#### Daniel
Mine's more on a personal, like, I read on your profile when you was talking about boot camp 

#### Daniel
and uh top guns you know applications that you you know your past experience i seen on there that you had a an action of doing companion animals you know uh for i don't want to say it's a corporation or a fund or just some type of organization but what got you into that how did you get into that 

#### Mike
Thank you. 

#### Marti
uh well there's several there's there's you know always loved dogs um and um in fact one of the ones i have here he's kind of sleeping they did their little hike this morning um he's a three legged 11 pound dog because he was born with bad kneecaps um and um i think that's part of the compassion. And I was lucky enough that my husband loves them, probably loves them more than loves me. I don't know. I've always had big dogs and he really wanted to keep Joey. And I was like, we hike a lot. Well, Joey will hike three miles and it shocks me. And I just don't tell him that can't do it. So I actually think that's kind of a mentoring thing too or a learning experience when talking with people is I never told this dog he couldn't walk more than three miles, you know, he just does it. We got pictures of him and Willow out, so it just works very well. So I think part of it was compassion. And then some of us, myself included, also then became involved in organizations that do animals and disaster. And I hate to remain Mike of the one that he went 

#### Mike
Mm. 

#### Marti
through a year and a half ago, but they did deploy some groups out there. And a lot of what they do 

#### Mike
Thank you. 

#### Marti
with animals and disaster may not be what you think. They've got like official ones or animal control or law enforcement, firemen who may do the rescues. But a lot of times what the organizations I volunteer with would actually take animals that were unclaimed or actually deliberately surrendered because what would happen, guys, is they would lose their homes and they were desperate to try to find a place just to get a roof over the head, a hotel or something. And then there was no place to put the animal and they didn't want the animals lost. 

#### Mike
Thank you. 

#### Marti
So then they would surrender. We get a form. We try to learn who their vet was, what their current status was on vaccinations. and then we would just get them out and get them, you know, take care of them for whatever time it took within reason. Usually in deployment situations, it would be up to a month. But, and then a lot of times they would come in, they'd try to come in and visit with their animals. So there was deliberate surrenders or ones that we got because we don't know what happened. i've done a couple of puppy mill rescues um i don't i don't know how an elderly lady and a disabled husband and a couple part-time workers took care of 500 dogs a day it was brutal the problem the problem is they couldn't so law enforcement went in okay and i've done a few of 

#### Mike
Mm-hmm. 

#### Marti
those. I worked at Greensburg Tornado of 2007. And we went in not just because of what the tornado itself, but because the guy who took over Pratt County Humane Society building just brought in animals right and left and had a parvo outbreak. And now that got seized. So then they had to, 

#### Mike
Mm. 

#### Marti
you know, kick him out and bring in law enforcement. And then they asked for some volunteers to help do what I said, you know, we clean it every day, we'd walk, we feed, we clean, you know, they like to say that we walk, we feed, we clean, and then we clean some more, and then we clean some more. So, you know, it's, those are some of the things that we had dealt with. A lot of animals came in, I can even work with horses to some degree, never really had to work with cows, but, you know, things happen. So a lot of it is understanding, again, the compassion and what these people are going through. And can you help keep their animals safe so they have one less thing to worry about? So that's a lot of what that had to do with. And every now and then I still get calls to deploy. But while I was working, it was hard because my last few years I was basically in security channel sales. And my schedule didn't allow me to take off with less than a week's notice to go somewhere and work for a few days on a crisis. So a lot of fire deployments, too, you know. 

#### Mike
I've been in high country in Colorado. 

#### Daniel
Thank you. Like I said, I know it was a little bit more personal, but it was me personally. I have I have more compassion for animals than I do people. I hate to say it, but yes. 

#### Marti
And it's getting worse all the time. Yeah. 

#### Mike
The animals are getting worse. 

#### Marti
I don't. 

#### Mike
The people are. 

#### Marti
The people. 

#### Marti
It's it's tough. I one of my neighbors who I walk with in the mornings and, you know, with Joey and Willow, she was talking. she's saying this for a while and sometimes she's got some ideas that are out there, but she said basically she feels the world is just deliberately trying to divide us all. And it's, it just feels like that every, every day. And, um, you know, we don't, you know, you know, it's just, it's just 

#### Mike
It just never quits coming. 

#### Marti
tough. And I think too, when you've suffered a lot too, you tend to have more compassion. We don't talk to a lot of either of our families. My husband's family hates me because I'm not Catholic. 

#### Mike
Thank you. 

#### Marti
My family doesn't like him because he's chastised them because I've helped them in some financial situations and done stuff and they don't even seem to appreciate it. And so it is what it is. Sometimes you just have to take a step back from people, 

#### Mike
Yeah. 

#### Marti
as Daniel would say. 

#### Mike
Yeah. Yeah. 

#### Daniel
Yeah. 

#### Mike
So, Luke, do you have any questions that we haven't hit? 

#### Luke
Well, Miss Marti, you've already been so helpful when it comes to, you know, when it comes to the platform. So most of all, my questions there were raised. But I thought I'd ask you, is there maybe, do you remember a certain mentee that maybe you guided that came from a true rookie situation and they went to a grand success that maybe you're most proud of? 

#### Marti
I don't know that I've had that many in number to make it a claim like that. But one of my first ones, Laura, you know, one of the reasons she got a good job was actually a contact. A friend of hers got a job at this health care company and then she got it. Then she started traveling. She found herself that after we were mentoring, we started mentoring like in the early spring of 2024. And in Alaska, I mean, she actually found herself on a trip to a business trip to Alaska. by September. That's the type of job she had. She found it really interesting. With her three kids, and then it was hybrid, she was able to work from home two days a week and work in the office three. It did very well for her. We talked about through a lot of things that would be successful. Like I said, the friend got her the job, but she was doing the training necessary to get there. And she was definitely a quick, a fairly quick success. Andrew has done a lot of things, but he's still a work in progress, but I think he's on the right track. And a lot of those decisions he now makes on his own. Now, you know, if I had, say, 10 mentees, then I suspect that, you know, like if I had a large number, although Andrew, I'm sorry, Mike would pick them very carefully for the program. So they had to be committed. But if I had like 10, my anticipation statistically is that like two would end up not working out real well. You know, five would be 

#### Marti
very good and maybe three would be successes very quickly. You know, that's just kind of the law of averages, but I haven't had that number yet. 

#### Mike
All right. Well, Marti, I really appreciate your time today. And I think the team has learned a lot about the mentor persona and the types of things that you would be using the system for. And we're going to go right from this this afternoon into some design sessions to talk about what we might build for you. So I hope that we can come back to you in a few weeks. 

#### Mike
Okay. 

#### Mike
and maybe have a prototype system up on the cloud that you could look at, and we could talk about what you think about what you see. So I'll try not to take up too much of your time, but I'll let you know when we have something that you can look at. 

#### Mike
Okay, great. 

#### Mike
Thank you so much for being with us today. 

#### Mike
Nice meeting you. Okay, you guys. Take care. It was nice meeting you all. You too. Nice to meet you too. 

#### Mike
Okay. 

#### Mike
Well, I hope I did that right. 

#### Mike
Everybody did a great job. Everybody did a great job. I hope that y'all feel like you learned a lot about who Marti is and about how she'll use the system. And so this afternoon when we get together and start talking about things, Daniel, remember we were discussing what is the landing page for the mentor persona? 

#### Mike
Yeah. 

#### Mike
What's the landing page? 

#### Mike
It's where she would actually go on. 

#### Mike
It's a dashboard of her apprentices and their progress, right? 

#### Mike
That's I mean, I'm just going to leave. 

#### Daniel
It's just like it is because everything that she said is almost here. 

#### Mike
That's your idea too. The 

#### Daniel
Almost. I mean, like I said, it's a rough. It's just a sketch, an idea, a draft. But I'm going to leave it just as it is. And I'm sure we'll have to add something or whatever. But like you said, it was supposed to be for the mentor itself, not the actual whole application. Just what. 

#### Mike
is the mentor. 

#### Daniel
Just what she would come in and log on to. And like I said, when you want to look at it, it's funny. 

#### Mike
I 

#### Daniel
Her specifics on notes, on personal notes versus notes too, that's there. Progress, that's there. I mean, I don't know how. I don't know how. 

#### Mike
You want me to tell you how? we had a design workshop where we already had you thinking about who is the mentor and what are 

#### Mike
Yeah. 

#### Mike
they going to need to do, right? We've already had that whole workshop that got the entire team thinking about who is a mentor and how are they going to use the system, right? And what you're seeing, Daniel, is design thinking in action. Us having that empathy exercise, thinking about what they do, us having the big ideas, what are going to make a difference for them. All of those things lead your mind to designing something. And to be honest, the chat design component of this has me really at this point reaching out for new ways because normally in a design session, a design workshop, when we were wanting to use these things, everybody would be sketching out their ideas and then sharing their ideas on a board and we'd have a discussion and we cut and paste, literally cut and paste paper around to discuss different ideas. That's really hard to do in a chat. So we'll figure out a way forward, but we're at the point to start to be thinking about what screens look like and how we lay out screens and navigation and all of those things. And for 

#### Mike
Thank you. 

#### Mike
Mary to be thinking about what's the data that's going to be on those screens. And for Lucky to be thinking about what's the interaction need to be like between the database and the front end so that I can make that easy on the front end. And Luke, we're continuing to target getting something launched in the cloud so that we can invite Marti to come and take a look at it. Oh, it's lunchtime break, guys. I think everybody should take an hour, go get some lunch, stop, reflect on what we learned in that interview, kind of think about that. 

#### Mike
Yes. It was good. I liked it. Yeah, I didn't think it was bad. 
