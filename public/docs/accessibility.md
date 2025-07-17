# Consider.it Accessibility

Considerit functionality meets WCAG 2.0 Level A accessibility requirements. The few exceptions are explained below. We have tried to go beyond accessibility standards by user testing with blind folks to identify usability issues. We have also augmented Considerit with a fallback for visually-impaired users who have trouble using the system to contact us to ask for help. We help each of these folks individually to understand the proposals being discussed and input their opinions.

## Outstanding accessibility issues

* It is not possible to use the keyboard to highlight different sections of the histogram.  
* It is not possible to use the keyboard to inspect a single user’s pro and con points that user thinks are important.   
* It is not possible to use the keyboard to get a list of the specific users who think a particular point is important. 

None of these are core features of Consider.it. 

# WCAG 2.0 Conformance Declaration

This WCAG Conformance statement is modeled after the Voluntary Product Accessibility Statement ([VPAT](https://www.itic.org/policy/accessibility/)) for Section 508, but using the Web Content Accessibility Guidelines ([WCAG](https://www.w3.org/TR/WCAG20/)) as conformance criteria instead. The format below is more useful than the existing VPAT format because Section 508 is out-of-date and its eventual Refresh will incorporate WCAG by reference. The format and some language borrowed from Accessibility leader [tenon.io](https://tenon.io).

Updated: May 2025
Name of Product: Consider.it  
Contact: Travis Kriplean, travis@consider.it

## Description of Support Levels

| Support Level | Description |
| :---- | :---- |
| Supports | Consider.it meets or exceeds the conformance criteria for this provision |
| Supports with Exceptions | Consider.it meets most of the conformance criteria for this provision, but some instances exist where the criteria are not fully met. |
| Does Not Support | Consider.it does not meet the conformance criteria for this provision in any meaningful way. |
| Not Applicable | This provision is not applicable to Consider.it. |

## 

## **WCAG Level A**

### Guideline 1.1 Text Alternatives

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.1.1 Non-Text Content** All non-text content that is presented to the user has a text alternative that serves the equivalent purpose, except for the situations listed below.  **Controls, Input**: If non-text content is a control or accepts user input, then it has a name that describes its purpose. **Time-Based Media**: If non-text content is time-based media, then text alternatives at least provide descriptive identification of the non-text content. **Test**: If non-text content is a test or exercise that would be invalid if presented in text, then text alternatives at least provide descriptive identification of the non-text content. **Sensory**: If non-text content is primarily intended to create a specific sensory experience, then text alternatives at least provide descriptive identification of the non-text content. **CAPTCHA**: If the purpose of non-text content is to confirm that content is being accessed by a person rather than a computer, then text alternatives that identify and describe the purpose of the non-text content are provided, and alternative forms of CAPTCHA using output modes for different types of sensory perception are provided to accommodate different disabilities. **Decoration, Formatting, Invisible**: If non-text content is pure decoration, is used only for visual formatting, or is not presented to users, then it is implemented in a way that it can be ignored by assistive technology.  | Supports | Considerit the platform only uses graphics for user avatars. Proper text alternatives are provided. Considerit can be customized for particular clients, including the ability to add custom homepage containing graphics, or proposals with embedded graphics. Those graphics can also be provided with text alternatives. It is the responsibility of the client to provide them to the Considerit team.   |

### 

### Guideline 1.2 Time-based Media

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.2.1 Audio-only and Video-only (Prerecorded)** For prerecorded audio-only and prerecorded video-only media, the following are true, except when the audio or video is a media alternative for text and is clearly labeled as such:  **Prerecorded Audio-only:** An alternative for time-based media is provided that presents equivalent information for prerecorded audio-only content. **Prerecorded Video-only:** Either an alternative for time-based media or an audio track is provided that presents equivalent information for prerecorded video-only content. | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide accessible alternatives. |
| **1.2.2 Captions (Prerecorded)** Captions are provided for all prerecorded audio content in synchronized media, except when the media is a media alternative for text and is clearly labeled as such.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide captions. |
| **1.2.3 Audio Description or Media Alternative (Prerecorded)** An alternative for time-based media or audio description of the prerecorded video content is provided for synchronized media, except when the media is a media alternative for text and is clearly labeled as such.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide accessible alternatives. |

### 

### Guideline 1.3 Adaptable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.3.1 Information and Relationships** Information, structure, and relationships conveyed through presentation can be programmatically determined or are available in text.  | Supports | Considerit uses proper markup for its content. Considerit structures all content with headings. All list-like content is constructed as lists. Considerit makes use of ARIA-landmark roles and HTML5 sectioning elements to structure each page. |
| **1.3.2 Meaningful Sequence** When the sequence in which content is presented affects its meaning, a correct reading sequence can be programmatically determined.  | Supports | The reading sequence of Considerit's user interface is programmatically determinable. The visual flow of Considerit's UI matches the programmatic flow. |
| **1.3.3 Sensory Characteristics** Instructions provided for understanding and operating content do not rely solely on sensory characteristics of components such as shape, size, visual location, orientation, or sound.  Note: For requirements related to color, refer to Guideline 1.4. | Supports | None of the instructions for Considerit rely solely on sensory characteristics. |

### 

### Guideline 1.4 Distinguishable

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.4.1 Use of Color** Color is not used as the only visual means of conveying information, indicating an action, prompting a response, or distinguishing a visual element.  | Supports | Considerit does not use color as the only means of conveying information, indicating an action, prompting a response, or distinguishing a visual element. Any information presented through the use of color is also conveyed in text or other programmatically distinguishable method. |
| **1.4.2 Audio Control** If any audio on a Web page plays automatically for more than 3 seconds, either a mechanism is available to pause or stop the audio, or a mechanism is available to control audio volume independently from the overall system volume level.  | Not applicable | Considerit does not provide content with audio. If a Considerit client includes audio content, it is their responsibility to use an audio player that conforms.  |

### Guideline 2.1 Keyboard Accessible

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.1.1 Keyboard** All functionality of the content is operable through a keyboard interface without requiring specific timings for individual keystrokes, except where the underlying function requires input that depends on the path of the user's movement and not just the endpoints.  | Supports with exceptions | All core functionality is keyboard accessible. A few tertiary features are not accessible by keyboard. See a description of these features [here](#outstanding-accessibility-issues). |
| **2.1.2 No Keyboard Trap** If keyboard focus can be moved to a component of the page using a keyboard interface, then focus can be moved away from that component using only a keyboard interface, and, if it requires more than unmodified arrow or tab keys or other standard exit methods, the user is advised of the method for moving focus away.  | Supports | There are no keyboard traps in Considerit. |
| **2.1.4 Character Key Shortcuts** If a keyboard shortcut is implemented in content using only letter (including upper- and lower-case letters), punctuation, number, or symbol characters, then at least one of the following is true: <br>Turn off: A mechanism is available to turn the shortcut off;<br>Remap: A mechanism is available to remap the shortcut to include one or more non-printable keyboard keys (e.g., Ctrl, Alt);<br>Active only on focus: The keyboard shortcut for a user interface component is only active when that component has focus.  | Supports | There are no character key shortcuts in Considerit. |

### Guideline 2.2 Enough Time

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.2.1 Timing Adjustable** For each time limit that is set by the content, at least one of the following is true:  **Turn off:** The user is allowed to turn off the time limit before encountering it; or **Adjust:** The user is allowed to adjust the time limit before encountering it over a wide range that is at least ten times the length of the default setting; or **Extend:** The user is warned before time expires and given at least 20 seconds to extend the time limit with a simple action (for example, "press the space bar"), and the user is allowed to extend the time limit at least ten times; or **Real-time Exception:** The time limit is a required part of a real-time event (for example, an auction), and no alternative to the time limit is possible; or **Essential Exception:** The time limit is essential and extending it would invalidate the activity; or **20 Hour Exception:** The time limit is longer than 20 hours. | Supports | No functionality within Considerit requires a timed response. |
| **2.2.2 Pause, Stop, Hide** For moving, blinking, scrolling, or auto-updating information, all of the following are true:  **Moving, blinking, scrolling:** For any moving, blinking or scrolling information that (1) starts automatically, (2) lasts more than five seconds, and (3) is presented in parallel with other content, there is a mechanism for the user to pause, stop, or hide it unless the movement, blinking, or scrolling is part of an activity where it is essential; and **Auto-updating:** For any auto-updating information that (1) starts automatically and (2) is presented in parallel with other content, there is a mechanism for the user to pause, stop, or hide it or to control the frequency of the update unless the auto-updating is part of an activity where it is essential. | Supports with exceptions | No content on Considerit blinks or scrolls. Proposals, points, and opinions in histograms automatically updates once every few minutes and that update cannot be stopped. |

### Guideline 2.3 Seizures

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.3.1 Three flashes or below** Web pages do not contain anything that flashes more than three times in any one second period, or the flash is below the general flash and red flash thresholds.  | Supports | No content within Considerit flashes more than 3 times. |

### Guideline 2.4 Navigable

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.4.1 Bypass Blocks** A mechanism is available to bypass blocks of content that are repeated on multiple Web pages.  | Supports | Considerit uses ARIA landmarks and headings to allow users to skip between sections of the page. |
| **2.4.2 Page Titled** Web pages have titles that describe topic or purpose.  | Supports  | Considerit provides a title on each page. |
| **2.4.3 Focus Order** If a Web page can be navigated sequentially and the navigation sequences affect meaning or operation, focusable components receive focus in an order that preserves meaning and operability.  | Supports | All focus order within Considerit makes sense and visual focus order mostly matches programmatic focus order. |
| **2.4.4 Link Purpose in context** The purpose of each link can be determined from the link text alone or from the link text together with its programmatically determined link context, except where the purpose of the link would be ambiguous to users in general.  | Supports | All Considerit links make sense within context. |

### Guideline 2.5 Input Modalities

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.5.1 Pointer Gestures** All functionality that uses multipoint or path-based gestures for operation can be operated with a single pointer without a path-based gesture, unless a multipoint or path-based gesture is essential. | | |
| **2.5.2 Pointer Cancellation** For functionality that can be operated using a single pointer, at least one of the following is true:<br>No Down-Event: The down-event of the pointer is not used to execute any part of the function;<br>Abort or Undo: Completion of the function is on the up-event, and a mechanism is available to abort the function before completion or to undo the function after completion;<br>Up Reversal: The up-event reverses any outcome of the preceding down-event;<br>Essential: Completing the function on the down-event is essential. | | |
| **2.5.3 Label in Name** For user interface components with labels that include text or images of text, the name contains the text that is presented visually. | | |
| **2.5.4 Motion Actuation** Functionality that can be operated by device motion or user motion can also be operated by user interface components and responding to the motion can be disabled to prevent accidental actuation, except when: <br>Supported Interface: The motion is used to operate functionality through an accessibility supported interface;<br>Essential: The motion is essential for the function and doing so would invalidate the activity. | | |


### Guideline 3.1 Readable

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.1.1 Language of the Page** The default human language of each Web page can be programmatically determined.  | Supports | The language of the page is indicated programmatically, through the use of the lang attribute on the HTMLelement |

### Guideline 3.2 Predictable

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.2.1 On Focus** When any component receives focus, it does not initiate a change of context.  | Supports | Considerit does not change context when an item gets focus |
| **3.2.2 On Input** Changing the setting of any user interface component does not automatically cause a change of context unless the user has been advised of the behavior before using the component.  | Supports | Considerit does not change context when the settings of a control has changed. |
| **3.2.6 Consistent Help** If a Web page contains any of the following help mechanisms, and those mechanisms are repeated on multiple Web pages within a set of Web pages, they occur in the same order relative to other page content, unless a change is initiated by the user: <br>Human contact details;<br>Human contact mechanism;<br>Self-help option;<br>A fully automated contact mechanism.<br>Note 1: A fully automated contact mechanism.<br>Note 2: For this Success Criterion, “the same order relative to other page content” can be thought of as how the content is ordered when the page is serialized. The visual position of a help mechanism is likely to be consistent across pages for the same page variation (e.g., CSS break-point). The user can initiate a change, such as changing the page’s zoom or orientation, which may trigger a different page variation. This criterion is concerned with relative order across pages displayed in the same page variation (e.g., same zoom level and orientation). | Supports | | 





### 

### Guideline 3.3 Input Assistance

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.3.1 Error Identification** If an input error is automatically detected, the item that is in error is identified and the error is described to the user in text.  | Supports | Considerit’s error handling approach identifies each error and discloses the nature of the error in an accessible field. |
| **3.3.2 Labels or Instructions** Labels or instructions are provided when content requires user input.  | Supports | All form fields are labelled properly and clearly. |
| **3.3.7 Redundant Entry** Information previously entered by or provided to the user that is required to be entered again in the same process is either: <br>auto-populated, or<br>available for the user to select.<br>Except when:<br>re-entering the information is essential,<br>the information is required to ensure the security of the content, or<br>previously entered information is no longer valid. | Supports | |


### Guideline 4.1 Compatible

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **4.1.2 Name, Role, Value** For all user interface components (including but not limited to: form elements, links and components generated by scripts), the name and role can be programmatically determined; states, properties, and values that can be set by the user can be programmatically set; and notification of changes to these items is available to user agents, including assistive technologies.  | Supports | All custom controls utilize relevant ARIA roles, states, and properties as needed for that type of control. |



## **WCAG Level AA**

### Guideline 1.2 Time-based Media

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.2.4 Captions (Live)** Captions are provided for all live audio content in synchronized media.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide captions. |
| **1.2.5 Audio Description (Prerecorded)** Audio description is provided for all prerecorded video content in synchronized media.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide description. |

### 

### Guideline 1.3 Adaptable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.3.4 Orientation** Content does not restrict its view and operation to a single display orientation, such as portrait or landscape, unless a specific display orientation is essential. |  |  |
| **1.3.5 Identify Input Purpose** The purpose of each input field collecting information about the user can be programmatically determined when: <br>- The input field serves a purpose identified in the Input Purposes for User Interface Components section; and<br>- The content is implemented using technologies with support for identifying the expected meaning for form input data.<br><br> |  |  |

### 



### Guideline 1.4 Distinguishable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.4.3 Color Contrast (Minimum)** The visual presentation of text and images of text has a contrast ratio of at least 4.5:1, except for the following:  **Large Text:** Large-scale text and images of large-scale text have a contrast ratio of at least 3:1; **Incidental:** Text or images of text that are part of an inactive user interface component, that are pure decoration, that are not visible to anyone, or that are part of a picture that contains significant other visual content, have no contrast requirement. **Logotypes:** Text that is part of a logo or brand name has no minimum contrast requirement. | Does not support | There are numerous low contrast text elements. Considerit may provide a high contrast mode in the future.  |
| **1.4.4 Resize Text** Except for captions and images of text, text can be resized without assistive technology up to 200 percent without loss of content or functionality.  | Supports | Considerit responds well to text-only resize up to 200%. However, horizontal scrolling is required. |
| **1.4.5 Images of Text** If the technologies being used can achieve the visual presentation, text is used to convey information rather than images of text except for the following:  <br>**Customizable:** The image of text can be visually customized to the user's requirements; <br>**Essential:** A particular presentation of text is essential to the information being conveyed. | Supports | No images on Considerit contain text. However, some Considerit clients upload banners for the homepage containing text. We offer homepage customization services that could replace those graphics with text. It is the client’s responsibility as to whether to use those services.  |
| **1.4.10 Reflow** Content can be presented without loss of information or functionality, and without requiring scrolling in two dimensions for: <br>- Vertical scrolling content at a width equivalent to 320 CSS pixels;<br>- Horizontal scrolling content at a height equivalent to 256 CSS pixels;<br><br>Except for parts of the content which require two-dimensional layout for usage or meaning. |  |  |
| **1.4.11 Non-text Contrast** The visual presentation of the following have a contrast ratio of at least 3:1 against adjacent color(s): <br>- User Interface Components: Visual information required to identify user interface components and states, except for inactive components or where the appearance of the component is determined by the user agent and not modified by the author;<br>- Graphical Objects: Parts of graphics required to understand the content, except when a particular presentation of graphics is essential to the information being conveyed. | | |
| **1.4.12 Text Spacing** In content implemented using markup languages that support the following text style properties, no loss of content or functionality occurs by setting all of the following and by changing no other style property:<br>- Line height (line spacing) to at least 1.5 times the font size;<br>- Spacing following paragraphs to at least 2 times the font size;<br>- Letter spacing (tracking) to at least 0.12 times the font size;<br>- Word spacing to at least 0.16 times the font size.<br><br>Exception: Human languages and scripts that do not make use of one or more of these text style properties in written text can conform using only the properties that exist for that combination of language and script. | | |
| **1.4.13 Content on Hover or Focus** Where receiving and then removing pointer hover or keyboard focus triggers additional content to become visible and then hidden, the following are true: <br>- Dismissible: A mechanism is available to dismiss the additional content without moving pointer hover or keyboard focus, unless the additional content communicates an input error or does not obscure or replace other content;<br>- Hoverable: If pointer hover can trigger the additional content, then the pointer can be moved over the additional content without the additional content disappearing;<br>- Persistent: The additional content remains visible until the hover or focus trigger is removed, the user dismisses it, or its information is no longer valid.<br><br>Exception: The visual presentation of the additional content is controlled by the user agent and is not modified by the author. | | |




### 

### Guideline 2.4 Navigable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.4.5 Multiple Ways** More than one way is available to locate a Web page within a set of Web pages except where the Web Page is the result of, or a step in, a process.  | Not applicable | Considerit is a web-based application with a very small number of core areas of interaction. |
| **2.4.6 Headings and Labels** Headings and labels describe topic or purpose.  | Supports | All of Considerit’s content and user interface elements are well structured and utilize effective and clear labels and headings. |
| **2.4.7 Focus Visible** Any keyboard operable user interface has a mode of operation where the keyboard focus indicator is visible.  | Supports | All items that get focus are given a clear on-screen indication. All items that get focus are indicated as having focus in a programmatic way. |
| **2.4.11 Focus Not Obscured (Minimum)** When a user interface component receives keyboard focus, the component is not entirely hidden due to author-created content.<br><br>Note 1: Where content in a configurable interface can be repositioned by the user, then only the initial positions of user-movable content are considered for testing and conformance of this Success Criterion.<br>Note 2: Content opened by the user may obscure the component receiving focus. If the user can reveal the focused component without advancing the keyboard focus, the component with focus is not considered hidden due to author-created content. | | |

###

### Guideline 2.5 Input Modalities

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.5.7 Dragging Movements** All functionality that uses a dragging movement for operation can be achieved by a single pointer without dragging, unless dragging is essential or the functionality is determined by the user agent and not modified by the author.<br><br>Note: This requirement applies to web content that interprets pointer actions (i.e. this does not apply to actions that are required to operate the user agent or assistive technology). | | |
| **2.5.8 Target Size (Minimum)** The size of the target for pointer inputs is at least 24 by 24 CSS pixels, except where: <br> Spacing: Undersized targets (those less than 24 by 24 CSS pixels) are positioned so that if a 24 CSS pixel diameter circle is centered on the bounding box of each, the circles do not intersect another target or the circle for another undersized target;<br>Equivalent: The function can be achieved through a different control on the same page that meets this criterion;<br>Inline: The target is in a sentence or its size is otherwise constrained by the line-height of non-target text;<br>User agent control: The size of the target is determined by the user agent and is not modified by the author;<br>Essential: A particular presentation of the target is essential or is legally required for the information being conveyed.<br>Note 1: Targets that allow for values to be selected spatially based on position within the target are considered one target for the purpose of the success criterion. Examples include sliders, color pickers displaying a gradient of colors, or editable areas where you position the cursor.<br>Note 2: For inline targets the line-height should be interpreted as perpendicular to the flow of text. For example, in a language displayed vertically, the line-height would be horizontal. | | |


### 

### Guideline 3.1 Readable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.1.2 Language of parts** The human language of each passage or phrase in the content can be programmatically determined except for proper names, technical terms, words of indeterminate language, and words or phrases that have become part of the vernacular of the immediately surrounding text.  | Does not support | Users can add content in their own language, and Considerit does not capture this. Moreover, sites translated into other languages aren’t always fully translated. To address this problem, Considerit provides a Google Translate widget that will translate all text to a given selected language.  |

### 

### Guideline 3.2 Predictable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.2.3 Consistent Navigation** Navigational mechanisms that are repeated on multiple Web pages within a set of Web pages occur in the same relative order each time they are repeated, unless a change is initiated by the user.  | Supports | Considerit requires little navigation. There is a repeating navigational element to return to the homepage on all non-homepage pages. |
| **3.2.4 Consistent Identification** Components that have the same functionality within a set of Web pages are identified consistently.  | Supports | All components that have the same functionality are identified consistently throughout the application. |

### 

### Guideline 3.3 Input Assistance

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.3.3 Error Suggestion** If an input error is automatically detected and suggestions for correction are known, then the suggestions are provided to the user, unless it would jeopardize the security or purpose of the content.  | Supports | Considerit’s error handling approach identifies each error and discloses the nature of the error in an accessible field. |
| **3.3.4 Error Prevention – legal, financial, data** For Web pages that cause legal commitments or financial transactions for the user to occur, that modify or delete user-controllable data in data storage systems, or that submit user test responses, at least one of the following is true:  Submissions are reversible. Data entered by the user is checked for input errors and the user is provided an opportunity to correct them. A mechanism is available for reviewing, confirming, and correcting information before finalizing the submission. | Supports | Considerit’s error handling approach identifies each error and discloses the nature of the error in an accessible field. For deleting user content, the user is prompted first with an “are you sure?” dialog. |
| **3.3.8 Accessible Authentication (Minimum)** A cognitive function test (such as remembering a password or solving a puzzle) is not required for any step in an authentication process unless that step provides at least one of the following: <br>Alternative: Another authentication method that does not rely on a cognitive function test.<br>Mechanism: A mechanism is available to assist the user in completing the cognitive function test.<br>Object Recognition: The cognitive function test is to recognize objects.<br>Personal Content: The cognitive function test is to identify non-text content the user provided to the Web site.<br>Note 1: What is perceived as the user interface component or sub-component (to determine enclosure or size) depends on its visual presentation. The visual presentation includes the component's visible content, border, and component-specific background. It does not include shadow and glow effects outside the component's content, background, or border.<br>Note 2: Examples of mechanisms that satisfy this criterion include:<br>support for password entry by password managers to reduce memory need, and<br>copy and paste to reduce the cognitive burden of re-typing. | | |

### 

### Guideline 4.1 Compatible

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **4.1.3 Status Messages** In content implemented using markup languages, status messages can be programmatically determined through role or properties such that they can be presented to the user by assistive technologies without receiving focus.  | | |

### 

## **WCAG 2.0 Level AAA**

Note: Does not include AAA criteria added in WCAG 2.1 or 2.2.

### Guideline 1.2 Time-based Media

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.2.6 Sign Language (Prerecorded)** Sign language interpretation is provided for all prerecorded audio content in synchronized media.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide sign language. |
| **1.2.7 Extended Audio Description (Prerecorded)** Where pauses in foreground audio are insufficient to allow audio descriptions to convey the sense of the video, extended audio description is provided for all prerecorded video content in synchronized media.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide description. |
| **1.2.8 Media Alternative (Prerecorded)** An alternative for time-based media is provided for all prerecorded synchronized media and for all prerecorded video-only media.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide an alternative. |
| **1.2.9 Audio-only (Live)** An alternative for time-based media that presents equivalent information for live audio-only content is provided.  | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to provide an alternative. |

### 

### Guideline 1.4 Distinguishable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **1.4.6 Contrast (Enhanced)** The visual presentation of text and images of text has a contrast ratio of at least 7:1, except for the following:  **Large Text:** Large-scale text and images of large-scale text have a contrast ratio of at least 4.5:1; **Incidental:** Text or images of text that are part of an inactive user interface component, that are pure decoration, that are not visible to anyone, or that are part of a picture that contains significant other visual content, have no contrast requirement. **Logotypes:** Text that is part of a logo or brand name has no minimum contrast requirement. | Does not support | There are numerous low contrast text elements. Considerit may provide a high contrast mode in the future.  |
| **1.4.7 Low or No Background Audio** For prerecorded audio-only content that (1) contains primarily speech in the foreground, (2) is not an audio CAPTCHA or audio logo, and (3) is not vocalization intended to be primarily musical expression such as singing or rapping, at least one of the following is true:  **No Background:** The audio does not contain background sounds. **Turn Off:** The background sounds can be turned off. **20 dB:** The background sounds are at least 20 decibels lower than the foreground speech content, with the exception of occasional sounds that last for only one or two seconds. | Not applicable | Considerit does not provide any content in time-based media. If clients add custom time-based media, it is their responsibility to conform to this requirement. |
| **1.4.8 Visual Presentation** For the visual presentation of blocks of text, a mechanism is available to achieve the following:  Foreground and background colors can be selected by the user. Width is no more than 80 characters or glyphs (40 if CJK). Text is not justified (aligned to both the left and the right margins). Line spacing (leading) is at least space-and-a-half within paragraphs, and paragraph spacing is at least 1.5 times larger than the line spacing. Text can be resized without assistive technology up to 200 percent in a way that does not require the user to scroll horizontally to read a line of text on a full-screen window. | Does not support |  |
| **1.4.9 Images of Text (No Exception)** Images of text are only used for pure decoration or where a particular presentation of text is essential to the information being conveyed.  | Not applicable | No images on Considerit contain text. However, some Considerit clients upload banners for the homepage containing text. We offer homepage customization services that could replace those graphics with text. It is the client’s responsibility as to whether to use those services.  |

### 

### Guideline 2.1 Keyboard Accessible

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.1.3 Keyboard (No Exception)** All functionality of the content is operable through a keyboard interface without requiring specific timings for individual keystrokes.  | Supports with exceptions | All core functionality is keyboard accessible. A few tertiary features are not accessible by keyboard. See a description of these features [here](#outstanding-accessibility-issues).  |

### 

### Guideline 2.2 Enough Time

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.2.3 No Timing** Timing is not an essential part of the event or activity presented by the content, except for non-interactive synchronized media and real-time events.  | Supports | No feature within Considerit requires timing. |
| **2.2.4 Interruptions** Interruptions can be postponed or suppressed by the user, except interruptions involving an emergency.  | Supports | No feature within Considerit will cause any interruption. |
| **2.2.5 Re-authenticating** When an authenticated session expires, the user can continue the activity without loss of data after re-authenticating.  | Not applicable | Considerit sessions don’t expire.  |

### 

### Guideline 2.3 Seizures

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.3.2 Three Flashes** Web pages do not contain anything that flashes more than three times in any one second period.  | Supports |  |

### 

### Guideline 2.4 Navigable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **2.4.8 Location** Information about the user's location within a set of Web pages is available.  | Does not support | Only light navigation is used. |
| **2.4.9 Link Purpose (Link Only)** A mechanism is available to allow the purpose of each link to be identified from link text alone, except where the purpose of the link would be ambiguous to users in general.  | Does not support | Many of the links in Considerit’s interface require context to fully understand. |
| **2.4.10 Section Headings** Section headings are used to organize the content.  | Supports  |  |

### 

### Guideline 3.1 Readable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.1.3 Unusual Words** A mechanism is available for identifying specific definitions of words or phrases used in an unusual or restricted way, including idioms and jargon.  | Does not support | Considerit does not provide definitions of any words or phrases. |
| **3.1.4 Abbreviations** A mechanism for identifying the expanded form or meaning of abbreviations is available.  | Supports with exception | In general, Considerit avoids the use of abbreviations and acronyms in our interface. However, users and clients can add abbreviations in their content, which we do not modify.  |
| **3.1.5 Reading Level** When text requires reading ability more advanced than the lower secondary education level after removal of proper names and titles, supplemental content, or a version that does not require reading ability more advanced than the lower secondary education level, is available.  | Does not support |  |
| **3.1.6 Pronunciation** A mechanism is available for identifying specific pronunciation of words where meaning of the words, in context, is ambiguous without knowing the pronunciation.  | Does not support | Although we are unaware of any words within Considerit to which this criteria applies, if/ where they do exist, the pronunciation is not specified. |

### 

### Guideline 3.2 Predictable

### 

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.2.5 Change on Request** Changes of context are initiated only by user request or a mechanism is available to turn off such changes.  | Supports | All changes of context are initiated by user request. |

### 

### Guideline 3.3 Input Assistance

| Success Criteria | Supporting features | Remarks and Explanations |
| :---- | :---- | :---- |
| **3.3.5 Help**  Context-sensitive help is available.  | Does not support | Context-sensitive help is not provided |
| **3.3.6 Error Prevention (All)**  For Web pages that require the user to submit information, at least one of the following is true:  Reversible: Submissions are reversible. Checked: Data entered by the user is checked for input errors and the user is provided an opportunity to correct them. Confirmed: A mechanism is available for reviewing, confirming, and correcting information before finalizing the submission. | Supports | Considerit’s error handling approach identifies each error and discloses the nature of the error in an accessible field. For deleting user content, the user is prompted first with an “are you sure?” dialog. |
