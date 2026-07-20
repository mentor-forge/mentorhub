# Journey Mapping

The purpose of a journey mapping exercise is to serialize needs, events, and ideas into a coherent user journey for a specific persona. We want to understand the sequence of steps they take, what they see and do at each step, and where joy or pain shows up — so we can record key events in user journey specifications.

**Journey:** _[e.g. Mentor Journey]_  
**Actor:** _[e.g. Marti the Mentor]_  
**Scope:** _[what part of the experience this map covers]_

### Observe

Observations should focus on the persona and the pages or moments they use. Prefer this form:

```
<[Persona]> needs a <page> where they can <enter/view/update> <data>
```

If you don't know what page it would be on, list it as a generic need. For example:

```
Marty needs a way to create a new Resource.
Marty needs a Resource page where she can view and update a resource.
```

You may also capture journey **events** as sticky-sized steps, for example:

```
opens dashboard → sees mentee progress → opens encounter → captures notes
```

When you're ready to start, reply with a thumbs up. When you have emptied your mind of all observations, react with a check-mark.

### Reflect

Work with the team to serialize the needs into a journey. Group related steps, resolve duplicates, and arrange them in time order. Call out handoffs between personas (e.g. Customer → Coordinator → Mentor → Mentee) where they appear.

#### Journey outline

1. _[Step]_
2. _[Step]_
3. _[Step]_

#### Needs by step

| Step | Need / page | Data enter / view / update |
|------|-------------|----------------------------|
| | | |

#### Handoffs and boundaries

- _persona A does X → persona B picks up Y_

### Make

Finalize the journey as a named sequence suitable for `Specifications/journeys.yaml` and related specs. Record:

- Journey **name**, **description**, and **actor**
- Key events to carry into product / OpenAPI / SPA work
- Follow-on exercises (Big Ideas, Prioritization, or Needs) if gaps remain

| Field | Value |
|-------|-------|
| name | |
| description | |
| actor | |
| key events | |
