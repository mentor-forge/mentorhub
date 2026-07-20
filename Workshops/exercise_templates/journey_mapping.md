# Journey Mapping

The purpose of this journey mapping exercise is to serialize needs, events, and ideas into a coherent user journey for _`Persona Name`_. We want to understand the sequence of steps they take, what they see and do at each step, and where joy or pain shows up — so we can record key events in user journey specifications.

**Journey:** *[e.g. Mentor Journey]*
**Actor:** *[e.g. Marti the Mentor]*  
**Scope:** *[what part of the experience this map covers]*

## Observe

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

## Reflect
LLM prompt:
```
Review all the observations below and replace the code block with a serialized list of the needs. Group related steps, resolve duplicates, and arrange them in time order. Call out handoffs between personas (e.g. Customer → Coordinator → Mentor → Mentee) where they appear.
```
**Observations**
```
## PASTE MESSAGES HERE ##
```
**Journey outline**

1. *[Step]*
2. *[Step]*
3. *[Step]*

**Handoffs and boundaries**
- *persona A does X → persona B picks up Y*

## Make

Create TODO Tickets to implement each step or group of steps. Include tickets at the Data Layer with identified Data Structures, at the API Layer with identified RBAC, and at the UI Layer with identified pages.
