# Coordinator Workshop - MentorHub Design Workshop

This workshop will help us to develop a better understanding of what we're creating for the coordinator persona. As a reminder, we have identified that the coordinator is responsible for matching crafts people with mentors and reporting on mentorship metrics to a customer. The coordinator domain **controls** the Customer and Profile data dictionaries. This domain is also responsible for integration with the IdP system to provide identity and login data to the system. 

---

## Empathy Exercise
The purpose of an Empathy Map exercise is to focus our attention on a particular individual and try to empathize with their current realities. 

Give the empathy exercise target a name and just enough context information to trigger a A sense of familiarity. Family circumstances, Hobbies, Interests, These are things that we can imagine quickly without biasing the empathy in any particular direction. 

### Observe
Please document your observations about Carol the Coordinator. Classify your observation it into one of these categories:

- **does** - What have you seen them do? What do you imagine they do?
- **says** - What have you heard them say?
- **thinks** - How do they reason about their work
- **feels** - What emotions do they show/share?

Example format:

```
does: Edits videos, Plays Disc Golf, drinks beer
says: Why are you doing that?
says: Let's go to Packs Pub
thinks: I'm the greatest editor in the world!
feels: Frustrated production takes so long
```

When you're ready to start, reply with a thumbs up, when you have emptied your mind of all observations, react with a check-mark.

### Reflect
Review the observations below and summarize them by category in the headings below that. Emphasize common observations. Highlight causal threads that allow you to follow a workflow.

#### Does

**Matching and onboarding (most common thread)** — Several observers described the same core loop:
1. **Gather** mentor and craftsperson/candidate information (Google Form, spreadsheets, general intake)
2. **Match** mentees with suitable mentors and **schedule** appointments
3. **Introduce** warmly by email or message (“Hello <mentor>, meet <craftsperson>”)
4. **Track** meetings and relationship progress over the program (e.g., 12-week commitment)

**Operations and logistics** — Controls meeting logistics, sponsorships, and financial decisions; stays organized and patient with people who are unsure of themselves.

**Communication** — Reaches out to mentors for matches; speaks with caring, warm, friendly tone to the whole team; may use email, video, and (desired) richer connection tools (Skype/Discord called out).

**Teach, coordinate, coach (product vision)** — Lucky’s synthesis was widely shared:
- *Teaches:* programming fundamentals, APIs, Git, debugging, workflows, readability/maintainability
- *Coordinates:* tasks, priorities, progress, team communication, dependencies, milestones, documentation
- *Coaches:* guides rather than gives answers; encourages problem-solving, confidence, and continuous learning

**Other observations** — Observes others and asks questions when she does not understand (inquisitive); some noted hands-on design/QA (CSS, HTML) and hospitality outside work (cookouts, family life).

#### Says

**Introductions and facilitation**
- “Hello <mentor>, meet <craftsperson>”
- Example coordinator voice: *“Hi, I’m Carol the Coordinator. I’m here to help guide coding projects, teach technical concepts, and coach developers through challenges. My goal is to keep learning practical, projects organized, and progress moving forward.”*

**Tone and style (consensus)** — Clear, structured, friendly but professional, educational not intimidating, practical and action-focused; caring in conversation; soothing/steady under stress (motherly/counseling tone imagined).

**Inquisitive and reflective**
- “I wonder how I can improve that—why is it taking so long?”
- Brief acknowledgments (“um okay”) when processing

**Personal and relational** — Family-oriented asides; invitations to connect socially (“Would anybody like to come over for a cookout?”).

#### Thinks

**Outcomes and quality of match**
- Hopes each match is a good fit; wonders how mentor–craftsperson relationships are going
- Hopes graduates fulfill the **12-week commitment**
- **Best outcome:** graduate lands a **job**
- Hopes **mentors stay engaged** and are not discouraged

**Mission and fit**
- Must genuinely care about the cause or she is in the wrong role
- Believes everyone deserves a **second chance** after incarceration
- Wants a **sense of community** across the program (Discord/Skype suggested)

**How she helps**
- Guides and teaches for understanding, not just task completion
- Proud to provide for family; grateful for meaningful work others may not appreciate
- It is her job to help everybody and address problems she can influence

#### Feels

**Joy and reward when things go right**
- **Joy when a graduate gets a job** (strongest shared emotional peak)
- Reward and purpose from her role in mentorship and education

**Empathy for participants**
- Empathy for graduates facing **re-entry complications**
- Care for people with **challenging pasts** and educational needs
- Compassion and patience for those who are unsure of themselves

**Stakes and responsibility**
- Deep care that matches and program experience work for everyone involved
- Personal drive around **family financial security** and fighting for her kids
- Broad sense of duty to help and fix problems where she can

**Causal thread (Does → Says → Thinks → Feels)**

```text
Collect candidates → match & schedule → warm intro → track meetings
        ↓                    ↓              ↓              ↓
   organized intake    "meet your mentor"   hope for fit   joy at job placement
        ↓                    ↓              ↓              ↓
   teach/coach/QA      caring, clear tone   12-week +     empathy for re-entry;
   sprint/docs         guide don't tell     community      reward in education role
```

### Make
Based on the empathy map, identify research, key pain points, job activities to focus on. What areas can we increase joy or decrease pain? Use these insights to inform the Big Ideas exercise.

---

## Big Ideas Exercise
The purpose of a big ideas exercise is to capture big ideas about how to improve the experience of a user. We want to focus on the meaningful outcome of an experience and not get bogged down in details at this point. The exercise is more interested in the quantity of observations than quality. We'd rather have your 10 weirdest ideas than your one best idea.

### Observe
Generate as many ideas as possible for improving the customer experience. Focus on meaningful outcomes rather than details. Include absurd or magical thinking!

Use this format for your ideas:

```
<who> does <what> and then <wow>
```

Example:

```
James clicks on the buy-it-now button, and then he can bypass the checkout process!
```

When you're ready to start, reply with a thumbs up, when you have emptied your mind of all observations, react with a check-mark.

### Reflect
Review all the ideas generated and:
- Identify patterns and groupings
- Discuss and reconcile similar ideas
- Keep the floor open for "YES AND!" moments to build on others' ideas

#### 1. Self-service intake (replace forms and manual data entry)
- Carol shares a signup link; mentors and candidates enter their own profiles
- *Combine with matching:* ranked “best resume” candidates at top of Carol’s review list

**Discuss:** Single onboarding flow for both personas vs separate mentor/candidate links.

---

#### 2. Smart matching (core coordinator job)
- Invite-mentors button → ranked potential matches → outbound email without leaving the app
- Personality / fit reviews when pairing mentor and mentee
- Profile opens with **three mentor matches with reasons**, not just names
- Candidate browses **photo + bio gallery**; selections flow to Carol for approval
- **Outcome thread:** connect on goals, availability, communication style, urgency; better relationships with less friction; mentors work with the right people, not the loudest request

**Discuss:** Merge “ranked resume,” “three matches with reasons,” and “personality review” into one **Match Score + explanation** UX.

---

#### 3. Scheduling and Carol’s calendar load
- Schedule-introduction button → finds mutual free time → calendar invites to all
- Scheduling “review” button → auto-replies based on Carol’s current availability
- Mentor message board surfaces **availability** for logistics
- Overload automation: calculates day capacity; auto-messages and reschedules interviews she cannot take

**Discuss:** One **Scheduling hub** (intro meetings, interviews, reviews) vs separate buttons per workflow.

---

#### 4. Email and workflow automation (less copy-paste)
- Match invites and notifications sent from the platform, not a personal email client
- Mentor replies to a match email → system updates match state without Carol retyping

**Discuss:** Pair with group 3 so email thread and calendar stay in sync.

---

#### 5. Visibility without chasing paperwork
- Dashboard of mentor/mentee meetings and progress—no harassing for updates
- Meetings on-platform → Carol sees times and summaries automatically
- Weekly dashboard: **one clear sentence** on what the mentee learned
- Pre-session **one-page brief**: progress, notes, ratings

**Discuss:** Same data layer feeding “weekly sentence,” “one-page brief,” and meeting summaries.

---

#### 6. Engagement and early warning (duplicate noted)
- **Last activity at a glance** (login, note, rating) — *same idea recorded twice*
- Stalled progress → gentle nudge suggestion before Carol gives up on the service
- Learning goal set → notification when complete, without digging through the app
- Path completion → **shareable badge / brag card** for family

**Discuss:** Single **Engagement panel**: activity, stall risk, goals, milestones.

---

#### 7. AI-assisted coordination (human in the loop)
- Message board questions → AI draft + copy to Carol
- **Evaluate conversation** (keywords) → suggest more/less support or rematch
- AI button on Carol’s own statements/conversations → **suggestive** next steps only
- Re-entry distress signals: surface candidates needing programs, services, employment (email/keyword targeting)

**Discuss:** One **AI copilot** with modes (Q&A routing, conversation health, re-entry flags) vs three separate AI buttons.

---

#### 8. Clarity for mentees (guidance, not features)
- No mentee feels lost or unsupported
- Every mentee always knows **who to talk to**, **next step**, and **where to get help quickly**

**Discuss:** In-app “next step” vs coordinator outreach—product vs process.

---

#### 9. Desired outcomes (why Carol cares)
- Mentees stay engaged instead of dropping off → Carol feels accomplishment
- Carol helps mentors avoid chaos, overload, and random requests
- Calm handling; organizational skills applied at scale

*These align with groups 2, 5, and 6—use as success metrics for Make/prioritization.*

---

#### 10. Outlier — confirm scope
- On sign-in, user **chooses whether to see ads** instead of forced ads

**Discuss:** Likely a different persona or product boundary; park unless advertising is in MentorHub scope.

---

#### Suggested combined ideas for Make (discussion starters)
| Working name | Merges |
|--------------|--------|
| **Self-serve roster** | Signup links + self-entered profiles |
| **Match Studio** | Ranked candidates, 3 matches with reasons, personality/fit, photo gallery → Carol approves |
| **Coordinator Command Center** | Progress dashboard, weekly sentence, one-page brief, meeting summaries |
| **Engagement Radar** | Last activity, stall nudges, goal-done alerts, completion badges |
| **Scheduling Copilot** | Mutual availability, calendar invites, auto-decline/reschedule when overloaded |
| **Inbox Zero for Matches** | In-app email, reply-to-update match state |
| **Coordinator AI (suggest-only)** | Message board triage, conversation health, re-entry keyword flags |

### Make
Create a list of unique ideas. Give each idea a clear name and description. Use this list as input to a priorities exercise if needed. 

---

## Retrospective Exercise
The purpose of a retrospective exercise is to celebrate our successes and identify opportunities for continuous improvement. 

### Observe
Make observations grouped into these four categories:

- **question**: Any questions you might have regarding the scope or process
- **worked**: Things that worked well
- **change**: Things that need to change
- **ideas**: New ideas to try next time

Example format:
```
question: When will we do this again?
worked: Jill rocked as team lead
change: All of our deliverables were late
ideas: T-Shirt size tasks before the next sprint
```

When you're ready to start, reply with a thumbs up, when you have emptied your mind of all observations, react with a check-mark.

### Reflect
Review the observations from Observe and organize them as a markdown outline with these four category headings:

#### Questions
#### What Worked
#### What Needs to Change
#### New Ideas to Try

**Bold** any item that appears more than once (verbatim duplicate) to highlight consensus points.

### Make
Create action items to:

- Answer unanswered questions
- Implement new ideas for improvement
- Address items that need to change

