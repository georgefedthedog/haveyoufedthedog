# Character Pose Sheet Rules

This file defines the rules for creating six-pose character asset sheets.

The asset style is a soft 3D cartoon illustration style for a playful family app.

---

## Standard Output

The default output is one single 3×2 image.

The image contains six square cells.

The default pose order is:

| Row        | Cell 1      | Cell 2   | Cell 3          |
| ---------- | ----------- | -------- | --------------- |
| Top row    | Idle        | Happy    | Sad             |
| Bottom row | Celebrating | Sleeping | Giving an award |

The final image must not contain visible grid lines, dividers, borders, labels, or captions.

---

## Required Poses

Every character pose sheet contains exactly six poses:

1. Idle
2. Happy
3. Sad
4. Celebrating
5. Sleeping
6. Giving an award

Do not omit poses.

Do not add extra poses unless the user specifically asks.

---

## Pose Definitions

### Idle

The default character pose.

The character should look calm, friendly, and approachable.

Suitable examples:

- standing calmly
- sitting neatly
- relaxed neutral posture
- gentle smile
- pleasant eyes

No props.

---

### Happy

The character should look clearly happy.

Suitable examples:

- big smile
- joyful expression
- raised arms, hands, or paws
- playful bounce
- eyes closed with happiness
- cheerful open mouth

No props.

---

### Sad

The character should look gently sad or disappointed.

Suitable examples:

- droopy eyes
- small tear
- lowered head
- seated posture
- worried eyebrows
- small frown

The sad pose must remain cute, soft, and non-distressing.

No props.

---

### Celebrating

The character should look excited and triumphant.

Suitable examples:

- cheering
- jumping
- raising arms, hands, or paws
- fist pump
- delighted expression
- success pose

Do not add confetti, fireworks, stars, sparkles, or scene decoration unless the user asks.

No props by default.

---

### Sleeping

The character should be peacefully asleep.

Suitable examples:

- curled up
- lying down
- sitting asleep
- resting with closed eyes
- calm smile

Avoid:

- beds
- pillows
- blankets
- moons
- stars
- sleep symbols
- scene props

Do not use “Z” symbols unless the user explicitly requests them.

---

### Giving an Award

The character should present an award.

This pose means the character is giving recognition, not simply celebrating for itself.

Suitable examples:

- holding out a gold trophy
- presenting a medal
- offering a rosette
- holding a badge
- presenting a ribbon

The expression should be warm, proud, and encouraging.

The award should be the only non-essential prop.

---

## Visual Style

All images must use this style:

Soft 3D cartoon illustration, children’s-book app aesthetic, gentle cel shading with subtle ambient occlusion, rounded forms, soft edges, no hard black outlines, warm pastel palette, playful family-app feel, clean and readable at small size.

The final result should feel like a charming storybook illustration mixed with soft clay-like 3D animation.

---

## Style Must Include

- soft 3D cartoon look
- rounded forms
- soft edges
- gentle cel shading
- subtle ambient occlusion
- warm pastel colours
- cute expressive face
- clean readable silhouette
- playful app-friendly personality
- family-friendly charm

---

## Style Must Avoid

Do not create:

- realistic render
- photorealistic image
- harsh 3D render
- glossy plastic toy render
- flat vector art
- anime
- manga
- comic-book art
- pixel art
- sketch art
- painterly concept art
- low-poly art
- dark cinematic lighting
- hard black outlines

---

## Canvas Rules

Every cell must be square.

Every cell must have the same solid bright purple background:

`#FF05E1`

The background must be plain.

The character must be centred in each cell.

The full character should be visible unless the user asks for a crop.

The character should fill the frame nicely without touching the edges.

---

## Background Rules

The background must contain:

- no scenery
- no room
- no garden
- no furniture
- no wall
- no floor
- no ground line
- no gradient
- no pattern
- no texture
- no cast shadow
- no decorative elements

Use only a flat solid `#FF05E1` background.

---

## Text Rules

The image must contain no text.

Do not include:

- labels
- captions
- pose names
- speech bubbles
- signs
- numbers
- letters
- UI elements

This applies to every cell.

---

## Grid Rules

The full image may be arranged as a 3×2 pose sheet.

However, the grid must not be visibly drawn.

There must be:

- no borders
- no dividers
- no frames
- no cell outlines
- no labels
- no captions

The six square cells should simply sit together cleanly.

---

## Shadow Rules

Do not place a shadow under the character.

Do not add a floor shadow, contact shadow, ground shadow, or reflection.

Subtle shading on the character itself is allowed.

Subtle ambient occlusion within the character form is allowed.

---

## Prop Rules

Props are not allowed unless they are essential to the character or required by the award pose.

Allowed identity props include:

- dog collar
- cat collar
- bin wheels
- bin lid
- bin handle
- plant pot
- fish bowl
- clothing
- glasses
- character accessories requested by the user

Allowed award props include:

- trophy
- medal
- rosette
- badge
- ribbon

Do not add:

- toys
- food
- furniture
- random household items
- confetti
- stars
- sparkles
- background props
- scenery props

Unless the user specifically requests them.

---

## Character Consistency Rules

The character must remain identical in all six cells.

Do not change:

- body shape
- proportions
- colours
- markings
- facial structure
- eye colour
- eye style
- nose shape
- mouth style
- accessories
- clothing
- collar
- wheels
- pot
- lid
- ears
- tail
- scale
- camera angle
- lighting
- render style

The sheet should look like one character posed six different ways.

It must not look like six different versions of a similar character.

---

## Camera Rules

Use the same camera angle across all six cells.

Preferred angle:

- front-facing
- or slight three-quarter view

Avoid:

- dramatic perspective
- top-down view
- side-only view
- extreme close-up
- inconsistent zoom
- cinematic angles

---

## Lighting Rules

Use the same lighting across all six cells.

Lighting should be:

- soft
- warm
- even
- readable
- gentle

Avoid:

- harsh shadows
- moody lighting
- dramatic lighting
- strong rim lighting
- coloured lighting effects

---

## Scale Rules

The character should appear at the same general scale in every cell.

Sleeping poses may be wider and lower, but should still feel consistent with the rest of the sheet.

Do not make one pose much larger or much smaller than the others.

---

## Animal Rules

For animal characters, preserve:

- fur colour
- markings
- ears
- tail
- muzzle
- paws
- collar
- eye colour
- body proportions

Animals should be cute, soft, rounded, and expressive.

Avoid realistic animal anatomy if it makes the asset less charming or less readable.

---

## Anthropomorphic Object Rules

For object characters, preserve:

- object shape
- object colour
- functional parts
- face placement
- limb style
- proportions
- scale

For a wheelie bin, preserve:

- green bin body
- lid
- handle
- wheels
- face placement
- arms
- hands
- proportions

The object should remain recognisable as the object.

---

## Human Character Rules

For human characters, preserve:

- hair
- skin tone
- clothing
- facial features
- accessories
- proportions
- pose-sheet style

Humans should look like soft 3D family-app avatars, not realistic people.

Avoid uncanny realism.

---

## Default Image Prompt Template

Create a single 3×2 character pose sheet for a family app.

Character:
[CHARACTER DESCRIPTION]

Create exactly six square cells in this order:

Top row:

1. Idle
2. Happy
3. Sad

Bottom row: 4. Celebrating 5. Sleeping 6. Giving an award

The character must remain identical in every cell: same body shape, same colours, same markings, same face, same accessories, same proportions, same camera angle, same lighting, same scale, and same rendering style.

Only the pose and expression should change.

Visual style:
Soft 3D cartoon illustration, children’s-book app aesthetic, gentle cel shading with subtle ambient occlusion, rounded forms, soft edges, no hard black outlines, warm pastel palette, playful family-app feel, clean and readable at small size. The style should feel like a charming storybook illustration mixed with soft clay-like 3D animation, not a realistic render.

Background:
Every cell must have a solid bright purple #FF05E1 background.

Strict rules:
No labels, no captions, no pose names, no text, no scene background, no floor, no wall, no ground line, no cast shadow under the character, no cell borders, no dividers, no props except essential character identity props and the award in the giving-an-award pose.

Pose details:
Idle: neutral friendly resting pose.
Happy: cheerful delighted pose.
Sad: gently sad, cute and non-distressing.
Celebrating: excited triumphant pose.
Sleeping: peacefully asleep.
Giving an award: warmly presenting an award such as a gold trophy, medal, rosette, badge, or ribbon.

---

## Negative Prompt

Avoid realistic render, photorealism, harsh 3D render, plastic toy render, hard black outlines, flat vector art, anime, manga, comic book style, pixel art, sketch, painterly style, low-poly style, dramatic lighting, harsh shadows, cast shadow, floor shadow, ground line, scene background, room, garden, wall, floor, furniture, gradients, patterns, text, labels, captions, pose names, speech bubbles, signs, borders, frames, cell dividers, inconsistent character, changed markings, changed colours, changed accessories, different face, different proportions, different camera angle, different lighting, different scale, extra props, clutter, confetti, sparkles, random objects.

---

## Quality Checklist

Before finalising, check:

- Does the image contain exactly six poses?
- Is the layout 3×2?
- Are the poses in the correct order?
- Is each cell square?
- Is the background solid #FF05E1?
- Is there no text?
- Are there no labels?
- Are there no visible cell borders?
- Are there no dividers?
- Is there no scene background?
- Is there no ground line?
- Is there no shadow under the character?
- Are props limited correctly?
- Is the character identical across all six poses?
- Is the style soft 3D cartoon?
- Is the asset readable at small size?

---

## Most Important Rule

The character must look identical across all six poses.

Consistency matters more than novelty.
