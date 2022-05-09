

styles += """
  #NewForumOnBoarding {
    background: #FFFFFF;
    box-shadow: 0 4px 6px 0 rgba(0,0,0,0.13);
    border-radius: 0 0 8px 8px;   
    max-width: 780px;
    margin: 48px auto 60px auto;
    padding: 24px 64px;
    border-top: 14px solid #{selected_color};
    position: relative;
  }



  #NewForumOnBoarding .header_wrapper {
    margin-bottom: 36px;
  }

  #NewForumOnBoarding h1 {
    color: #{selected_color};
    font-weight: 700;
    font-size: 26px;

  }

  #NewForumOnBoarding .header_subtitle {
    font-size: 18px;
    color: #5D5C5C;
  }

  #NewForumOnBoarding ul {
    list-style: none;
    padding: none;
  }

  #NewForumOnBoarding .onboard_item {
    display: flex;
    margin-bottom: 18px;
  }

  #NewForumOnBoarding .onboard_item .checkbox {
    display: inline-block;
    width: 24px;
    height: 24px;
    border: 2px solid transparent;
    border-radius: 50%;
    flex-shrink: 0;
  } 

  #NewForumOnBoarding .onboard_item.complete .checkbox {
    border-color: #69BD8D;
    background-color: #69BD8D;
  }

  #NewForumOnBoarding .onboard_item.complete .checkbox:after {
    content: "✓";
    color: white;
    font-size: 18px;
    position: relative;
    top: -2px;
    left: 3px;
  }

  

  #NewForumOnBoarding .onboard_item.incomplete .checkbox {
    border-color: #C5C5C5;
  }

  #NewForumOnBoarding .onboard_item .label {
    margin-left: 24px;
    font-size: 17px;
  }

  #NewForumOnBoarding .close_checklist {
    position: absolute;
    right: 20px;
    top: 10px;
    color: #{selected_color};
    text-decoration: none;
    font-weight: 600;
    font-size: 20px;
  }

  #NewForumOnBoarding button.done_onboarding {
    margin-top: 0px;
    color: white;
    background-color: #{selected_color};
    border: none;
    padding: 8px 24px;
    font-weight: 700;
    border-radius: 8px;
  }


"""

window.NewForumOnBoarding = ReactiveComponent
  displayName: 'NewForumOnBoarding'

  render : -> 
    current_user = fetch '/current_user'
    return SPAN null if !current_user.is_admin

    subdomain = fetch '/subdomain'
    return SPAN null if subdomain.customizations.onboarding_complete

    has_initial_list = subdomain.customizations['list/initial']
    list_count = get_all_lists().length

    task_one_complete = subdomain.customizations.banner.title?.length > 0
    task_two_complete = !has_initial_list
    task_three_complete = (list_count >= 1 && !has_initial_list) || list_count >= 2

    tasks_completed = task_one_complete && task_two_complete && task_three_complete

    onboard_item = (label, completed) ->

      LI 
        className: "onboard_item #{if completed then 'complete' else 'incomplete'}"

        SPAN 
          className: 'checkbox'

        SPAN 
          className: 'label'
          dangerouslySetInnerHTML: __html: label

    complete_onboarding = ->
      subdomain.customizations.onboarding_complete = true
      save subdomain


    DIV 
      id: 'NewForumOnBoarding'
      BUTTON 
        className: 'close_checklist like_link'
        onClick: complete_onboarding
        'x'

      DIV 
        className: 'header_wrapper'



        H1 null, 
          if !tasks_completed
            "Welcome to your new forum!"
          else 
            "Congrats!"

        DIV 
          className: 'header_subtitle'

          if !tasks_completed
            'A checklist to get started:'
          else 
            """When you’re ready, you can invite your community to participate. There are also more settings 
               accessible via the menu in the upper right."""


      if tasks_completed
        DIV null, 
          ConfettiCelebration()
          BUTTON 
            className: 'done_onboarding'
            onClick: complete_onboarding
            "done"

      else 
        UL null,

          onboard_item "Edit the Banner to introduce people to your forum.", task_one_complete
          onboard_item "Experiment with the question below. Delete it when you’re done.", task_two_complete
          onboard_item "Start your own conversation.", task_three_complete





# From https://codepen.io/zer0kool/pen/KjZWRW
styles += """
.confetti {
    display: flex;
    justify-content: center;
    align-items: center;
    position: absolute;
    width: 100%;
    height: 100%;
    overflow: hidden;
    z-index: 1000;
    pointer-events: none;
    top: 0;
    left: 0;
}
.confetti-piece {
    position: absolute;
    width: 10px;
    height: 30px;
    background: #ffd300;
    top: 0;
    opacity: 0;
}
.confetti-piece:nth-child(1) {
    left: 7%;
    transform: rotate(-40deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 182ms;
    animation-duration: 1116ms;
}
.confetti-piece:nth-child(2) {
    left: 14%;
    transform: rotate(4deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 161ms;
    animation-duration: 1076ms;
}
.confetti-piece:nth-child(3) {
    left: 21%;
    transform: rotate(-51deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 481ms;
    animation-duration: 1103ms;
}
.confetti-piece:nth-child(4) {
    left: 28%;
    transform: rotate(61deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 334ms;
    animation-duration: 708ms;
}
.confetti-piece:nth-child(5) {
    left: 35%;
    transform: rotate(-52deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 302ms;
    animation-duration: 776ms;
}
.confetti-piece:nth-child(6) {
    left: 42%;
    transform: rotate(38deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 180ms;
    animation-duration: 1168ms;
}
.confetti-piece:nth-child(7) {
    left: 49%;
    transform: rotate(11deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 395ms;
    animation-duration: 1200ms;
}
.confetti-piece:nth-child(8) {
    left: 56%;
    transform: rotate(49deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 14ms;
    animation-duration: 887ms;
}
.confetti-piece:nth-child(9) {
    left: 63%;
    transform: rotate(-72deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 149ms;
    animation-duration: 805ms;
}
.confetti-piece:nth-child(10) {
    left: 70%;
    transform: rotate(10deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 351ms;
    animation-duration: 1059ms;
}
.confetti-piece:nth-child(11) {
    left: 77%;
    transform: rotate(4deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 307ms;
    animation-duration: 1132ms;
}
.confetti-piece:nth-child(12) {
    left: 84%;
    transform: rotate(42deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 464ms;
    animation-duration: 776ms;
}
.confetti-piece:nth-child(13) {
    left: 91%;
    transform: rotate(-72deg);
    animation: makeItRain 1000ms infinite ease-out;
    animation-delay: 429ms;
    animation-duration: 818ms;
}
.confetti-piece:nth-child(odd) {
    background: #7431e8;
}
.confetti-piece:nth-child(even) {
    z-index: 1;
}
.confetti-piece:nth-child(4n) {
    width: 5px;
    height: 12px;
    animation-duration: 2000ms;
}
.confetti-piece:nth-child(3n) {
    width: 3px;
    height: 10px;
    animation-duration: 2500ms;
    animation-delay: 1000ms;
}
.confetti-piece:nth-child(4n-7) {
  background: red;
}
@keyframes makeItRain {
    from {opacity: 0;}
    50% {opacity: 1;}
    to {transform: translateY(350px);}
}

"""
ConfettiCelebration = ->
  DIV 
    className: "confetti"
    dangerouslySetInnerHTML: __html: """
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
      <div class="confetti-piece"></div>
    """    



