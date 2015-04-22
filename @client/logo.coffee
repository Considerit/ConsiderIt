window.drawLogo = (height, main_text_color, o_text_color) -> 
  main_text_color = main_text_color or 'white'
  o_text_color = o_text_color or logo_red

  height = height or 58
  width = width or height * 284 / 58

  SVG 
    width: width 
    height: height 
    viewBox: "0 0 284 58" 
    version: "1.1" 
    xmlns: "http://www.w3.org/2000/svg" 

    G null,

      PATH
        fill: main_text_color
        d: """
          M18.2811874,48.356 
          C24.1163223,48.3559999 28.0501221,47.5510218 32.5084274,43.599315 
          C32.9673706,43.1801946 33.0984972,42.4018281 32.5739907,41.9827077 
          L30.2137104,37.099623 
          C29.8203305,36.740377 29.0991341,36.6805026 28.5746276,37.099623 
          C25.8209684,39.1353508 22.4772394,40.5124608 18.5434406,40.5124607 
          C14.4641389,40.5124606 9.32086755,37.716503 9.32086787,29.1762513 
          C9.32086836,20.6359996 15.4629989,17.6360006 18.2811869,17.6360001 
          C22.4641385,17.636 25.4641379,19.6359996 27.5746276,21.2528796 
          C28.0991341,21.7318743 28.7547672,21.7318743 29.2137104,21.2528796 
          L32.5739907,17.001801 
          C33.0984972,16.5228062 33.0984972,15.804314 32.5084274,15.3253193 
          C28.0501221,11.6729842 24.903082,10.236 18.2811874,10.236 
          C8.41026668,10.236 0.0764406792,17.8200837 0.0764406792,29.3558743 
          C0.0764406792,40.2729625 8.41026668,48.3560001 18.2811874,48.356 
          Z 
          M38.1601385,33.164 
          C38.1601385,41.444 44.7841385,48.356 52.9201385,48.356 
          C61.0561385,48.356 67.6801385,41.444 67.6801385,33.164 
          C67.6801385,25.028 61.0561385,18.116 52.9201385,18.116 
          C44.7841385,18.116 38.1601385,25.028 38.1601385,33.164 
          C38.1601385,33.164 38.1601385,25.028 38.1601385,33.164 
          Z 
          M46.0081385,33.164 
          C46.0081385,29.132 49.0321385,25.892 52.9201385,25.892 
          C56.7361385,25.892 59.8321385,29.132 59.8321385,33.164 
          C59.8321385,37.268 56.7361385,40.58 52.9201385,40.58 
          C49.0321385,40.58 46.0081385,37.268 46.0081385,33.164 
          C46.0081385,33.164 46.0081385,37.268 46.0081385,33.164 
          Z 
          M74.0881385,46.268 
          C74.0881385,46.988 74.7361385,47.636 75.4561385,47.636 
          L80.7841385,47.636 
          C82.1521385,47.636 82.5841385,47.276 82.5841385,46.268 
          L82.5841385,30.428 
          C83.3041385,28.484 85.6081385,25.892 89.3521385,25.892 
          C92.8081385,25.892 94.7521385,28.268 94.7521385,32.012 
          L94.7521385,46.268 
          C94.7521385,46.988 95.3281385,47.636 96.1201385,47.636 
          L102.024139,47.636 
          C102.744139,47.636 103.392139,46.988 103.392139,46.268 
          L103.392139,32.444 
          C103.392139,24.956 99.7201385,18.116 90.5761385,18.116 
          C85.0321385,18.116 81.5041385,21.212 80.4241385,22.364 
          L79.4161385,19.7 
          C79.2001385,19.196 78.8401385,18.836 78.1921385,18.836 
          L75.4561385,18.836 
          C74.7361385,18.836 74.0881385,19.412 74.0881385,20.204 
          C74.0881385,20.204 74.0881385,19.412 74.0881385,20.204 
          L74.0881385,46.268 
          Z 
          M110.304139,45.692 
          C111.816139,46.844 115.128139,48.356 119.880139,48.356 
          C127.152139,48.356 131.328139,44.324 131.328139,39.572 
          C131.328139,33.956 127.152139,31.58 121.608139,29.42 
          C118.944139,28.34 117.648139,27.908 117.648139,26.612 
          C117.648139,25.676 118.368139,24.956 120.096139,24.956 
          C122.832139,24.956 126.072139,26.468 126.072139,26.468 
          C126.648139,26.684 127.440139,26.612 127.800139,25.964 
          L129.600139,22.292 
          C129.960139,21.572 129.600139,20.78 128.952139,20.348 
          C127.440139,19.34 124.344139,18.116 120.096139,18.116 
          C112.752139,18.116 109.512139,22.22 109.512139,26.612 
          C109.512139,31.004 112.104139,33.956 117.648139,36.116 
          C121.464139,37.628 122.472139,38.42 122.472139,39.716 
          C122.472139,40.94 121.464139,41.516 120.024139,41.516 
          C116.712139,41.516 113.472139,39.788 113.472139,39.788 
          C112.824139,39.428 112.104139,39.572 111.816139,40.292 
          L109.872139,44.18 
          C109.584139,44.756 109.872139,45.332 110.304139,45.692 
          C110.304139,45.692 109.872139,45.332 110.304139,45.692 
          Z 
          M137.664139,46.268 
          C137.664139,46.988 138.312139,47.636 139.032139,47.636 
          L145.008139,47.636 
          C145.728139,47.636 146.376139,46.988 146.376139,46.268 
          L146.376139,20.204 
          C146.376139,19.412 145.728139,18.836 145.008139,18.836 
          L139.032139,18.836 
          C138.312139,18.836 137.664139,19.412 137.664139,20.204 
          C137.664139,20.204 137.664139,19.412 137.664139,20.204 
          L137.664139,46.268 
          Z 
          M166.680139,48.356 
          C172.728139,48.356 176.112139,44.036 176.112139,44.036 
          L176.832139,46.268 
          C177.048139,47.06 177.552139,47.636 178.200139,47.636 
          L181.008139,47.636 
          C181.728139,47.636 182.376139,46.988 182.376139,46.268 
          L182.376139,1.604 
          C182.376139,0.884 181.728139,0.236 181.008139,0.236 
          L174.888139,0.236 
          C174.168139,0.236 173.520139,0.884 173.520139,1.604 
          L173.520139,19.412 
          C172.224139,18.908 169.992139,18.116 167.112139,18.116 
          C158.544139,18.116 152.856139,24.812 152.856139,33.236 
          C152.856139,41.516 158.832139,48.356 166.680139,48.356 
          Z 
          M161.208139,33.236 
          C161.208139,29.204 164.160139,25.892 168.192139,25.892 
          C171.792139,25.892 173.808139,27.548 173.808139,27.548 
          L173.808139,35.9 
          C173.304139,37.628 171.576139,40.58 167.760139,40.58 
          C163.944139,40.58 161.208139,37.268 161.208139,33.236 
          C161.208139,33.236 161.208139,37.268 161.208139,33.236 
          Z 
          M188.856139,33.236 
          C188.856139,41.516 194.976139,48.356 203.616139,48.356 
          C208.296139,48.356 211.968139,46.628 214.344139,44.396 
          C215.064139,43.82 214.920139,43.028 214.416139,42.524 
          L211.464139,39.14 
          C210.960139,38.564 210.312139,38.708 209.592139,39.14 
          C208.296139,40.076 206.208139,40.94 203.976139,40.94 
          C199.800139,40.94 197.280139,37.628 197.064139,34.676 
          L215.496139,34.676 
          C216.144139,34.676 216.792139,34.172 216.864139,33.452 
          C216.936139,32.948 217.008139,32.012 217.008139,31.508 
          C217.008139,23.732 210.960139,18.116 203.544139,18.116 
          C194.976139,18.116 188.856139,25.1 188.856139,33.236 
          C188.856139,33.236 188.856139,25.1 188.856139,33.236 
          Z 
          M197.712139,29.636 
          C198.072139,26.9 200.448139,24.74 203.328139,24.74 
          C206.064139,24.74 208.368139,26.972 208.584139,29.636 
          C208.584139,29.636 208.368139,26.972 208.584139,29.636 
          L197.712139,29.636 
          Z 
          M223.056139,46.268 
          C223.056139,46.988 223.704139,47.636 224.424139,47.636 
          L229.968139,47.636 
          C230.976139,47.636 231.624139,47.276 231.624139,46.268 
          L231.624139,28.844 
          C232.128139,27.836 233.856139,25.892 236.736139,25.892 
          C237.528139,25.892 238.608139,26.252 238.824139,26.324 
          C239.400139,26.612 240.120139,26.324 240.480139,25.676 
          L243.144139,20.996 
          C244.008139,19.196 240.984139,18.116 237.600139,18.116 
          C233.136139,18.116 230.472139,21.14 229.464139,22.58 
          L228.456139,19.772 
          C228.240139,19.196 227.808139,18.836 227.160139,18.836 
          L224.424139,18.836 
          C223.704139,18.836 223.056139,19.412 223.056139,20.204 
          C223.056139,20.204 223.056139,19.412 223.056139,20.204 
          L223.056139,46.268 
          Z 
          M247.608139,46.268 
          C247.608139,46.988 248.256139,47.636 248.976139,47.636 
          L254.952139,47.636 
          C255.672139,47.636 256.320139,46.988 256.320139,46.268 
          L256.320139,20.204 
          C256.320139,19.412 255.672139,18.836 254.952139,18.836 
          L248.976139,18.836 
          C248.256139,18.836 247.608139,19.412 247.608139,20.204 
          C247.608139,20.204 247.608139,19.412 247.608139,20.204 
          L247.608139,46.268 
          Z 
          M266.472139,39.068 
          C266.472139,44.9 268.920139,48.356 274.464139,48.356 
          C277.992139,48.356 282.672139,46.7 283.032139,46.484 
          C283.752139,46.196 284.112139,45.476 283.824139,44.756 
          L282.384139,40.22 
          C282.168139,39.5 281.592139,39.14 280.800139,39.428 
          C280.008139,39.716 278.496139,40.22 277.272139,40.22 
          C276.120139,40.22 275.040139,39.932 275.040139,37.916 
          L275.040139,26.396 
          L281.376139,26.396 
          C282.168139,26.396 282.744139,25.748 282.744139,25.028 
          L282.744139,20.204 
          C282.744139,19.412 282.168139,18.836 281.376139,18.836 
          L275.040139,18.836 
          L275.040139,10.772 
          C275.040139,10.052 274.464139,9.404 273.744139,9.404 
          L267.840139,9.476 
          C267.120139,9.476 266.472139,10.124 266.472139,10.844 
          L266.472139,18.836 
          L264.024139,18.836 
          C263.304139,18.836 262.728139,19.412 262.728139,20.204 
          L262.728139,25.028 
          C262.728139,25.748 263.304139,26.396 264.024139,26.396 
          L266.472139,26.396 
          L266.472139,39.068 
          Z
        """ 

      CIRCLE 
        fill: o_text_color
        cx: "252.25"
        cy: "53.25"
        r: "4.25"
