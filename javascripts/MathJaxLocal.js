MathJax.Hub.Config({
    jax: ["input/TeX","output/HTML-CSS"],
    extensions: ["tex2jax.js","MathMenu.js","MathZoom.js"],
    tex2jax:
        {
            inlineMath: [ ['$','$'], ['\\(','\\)'] ],
            displayMath: [ ['$$','$$'], ['\\[','\\]'] ],
            skipTags: ["script","noscript","style","textarea","pre","code"],
            processEscapes: true
        },
    TeX:
        {
            equationNumbers: { autoNumber: "AMS" },
            TagSide: "left",

        },
    "HTML-CSS": { availableFonts: ["TeX"] }
    });