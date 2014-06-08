function h(a) {
    return document.querySelector(a)
}
function m(a) {
    return document.querySelectorAll(a)
}
HTMLElement.prototype.c = HTMLElement.prototype.querySelector;
HTMLElement.prototype.l = HTMLElement.prototype.querySelectorAll;
HTMLElement.prototype.index = function () {
    return Array.prototype.indexOf.call(this.parentNode.childNodes, this)
};
window.requestAnimationFrame || (window.requestAnimationFrame = window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || function (a) {
    setTimeout(a, 1E3 / 60)
});
window.cancelAnimationFrame || (window.cancelAnimationFrame = window.webkitCancelAnimationFrame || window.mozCancelAnimationFrame || window.oCancelAnimationFrame || function (a) {
    clearTimeout(a)
});
window.matchesSelector || (HTMLElement.prototype.matchesSelector = HTMLElement.prototype.webkitMatchesSelector || HTMLElement.prototype.mozMatchesSelector || HTMLElement.prototype.Ba);
window.la = function () {
    var a = document.body.style;
    return "webkitTransition" in a ? "webkitTransitionEnd" : "mozTransition" in a ? "transitionend" : "oTransition" in a ? "otransitionend" : "transitionend"
};

function n(a, b) {
    for (var c = a.parentNode; c !== document;) {
        if (c.matchesSelector(b)) return c;
        c = c.parentNode
    }
    return null
}
NodeList.prototype.forEach = Array.prototype.forEach;
Array.prototype.contains = function (a) {
    for (var b = this.length; b--;) if (this[b] === a) return !0;
    return !1
};
Array.prototype.H = function () {
    return 0 < this.length ? this[this.length - 1] : this[0]
};
NodeList.prototype.H = Array.prototype.H;
Array.prototype.remove = function (a) {
    Array.isArray(a) || (a = [a]);
    for (var b = a.length - 1; 0 <= b; b--) for (var c = this.length - 1; 0 <= c; c--) this[c] === a[b] && this.splice(c, 1);
    return this
};

function p(a, b) {
    var c = this;
    a.split(" ").forEach(function (a) {
        c.addEventListener(a, b)
    })
}
window.d = p;
document.d = p;
HTMLElement.prototype.d = p;

function u() {
    this.search = this.m = this.n = this.u = void 0
}
u.prototype = {
    g: function () {
        this.m = document.getElementsByClassName("book-parts")[0];
        this.n = document.getElementById("shortstack");
        this.u = document.getElementsByTagName("article")[0];
        this.search = document.getElementById("search");
        this.o();
        window.addEventListener("orientationchange", this.ua, !0)
    },
    M: function () {
        var a = document.querySelectorAll("figure > img"),
            b = document.getElementsByClassName("inline-graphic");
        Array.prototype.forEach.call(a, function (a) {
            a.removeAttribute("height");
            a.removeAttribute("width")
        });
        Array.prototype.forEach.call(b, function (a) {
            a.removeAttribute("height");
            a.removeAttribute("width")
        })
    },
    o: function () {
        ipad.n.addEventListener("click", ipad.U);
        ipad.u.addEventListener("click", ipad.v);
        ipad.search.addEventListener("click", ipad.T)
    },
    T: function (a) {
        "FORM" === a.target.nodeName && (document.getElementById("ssi_SearchField").classList.toggle("enabled"), ipad.search.classList.toggle("enabled"))
    },
    v: function () {
        ipad.m.classList.remove("open");
        ipad.n.classList.remove("enabled")
    },
    U: function () {
        ipad.m.classList.toggle("open");
        ipad.n.classList.toggle("enabled")
    },
    ua: function () {
        90 === Math.abs(window.orientation) && ipad.m.classList.contains("open") && ipad.m.classList.remove("open")
    }
};
document.addEventListener("DOMContentLoaded", function () {
    /(iPad).*AppleWebKit/i.test(navigator.userAgent) ? (ipad = new u, ipad.g()) : ipad = void 0
});

function v() {
    this.search = this.A = this.m = this.n = this.u = void 0
}
v.prototype = {
    g: function () {
        this.m = document.getElementsByClassName("book-parts")[0];
        this.n = document.getElementById("shortstack");
        this.u = document.getElementsByTagName("article")[0];
        this.A = document.getElementById("big_button");
        this.search = document.getElementById("search");
        this.o();
        this.M()
    },
    M: function () {
        var a = document.querySelectorAll("figure > img");
        Array.prototype.forEach.call(a, function (a) {
            a.removeAttribute("height");
            a.removeAttribute("width")
        });
        Array.prototype.forEach.call(document.getElementsByClassName("inline-graphic"),

        function (a) {
            a.removeAttribute("height");
            a.removeAttribute("width")
        })
    },
    o: function () {
        iphone.n.addEventListener("click", iphone.U);
        iphone.u.addEventListener("click", iphone.v);
        iphone.A.addEventListener("click", iphone.v);
        iphone.search.addEventListener("click", iphone.T)
    },
    T: function (a) {
        "FORM" === a.target.nodeName && (document.getElementById("ssi_SearchField").classList.toggle("enabled"), iphone.search.classList.toggle("enabled"))
    },
    v: function () {
        iphone.m.classList.remove("open");
        iphone.A.classList.remove("active");
        iphone.n.classList.remove("enabled");
        document.querySelector(".chapter").classList.remove("frozen")
    },
    U: function () {
        iphone.m.classList.toggle("open");
        iphone.A.classList.add("active");
        iphone.n.classList.toggle("enabled");
        document.querySelector(".chapter").classList.toggle("frozen")
    }
};
document.addEventListener("DOMContentLoaded", function () {
    /(iP(hone|opd)).*AppleWebKit/i.test(navigator.userAgent) ? (iphone = new v, iphone.g()) : iphone = void 0
});

function History() {
    this.Z = null;
    this.Y = !0;
    this.$ = this.j = this.k = null
}
History.prototype = {
    g: function () {
        var a = document.getElementsByClassName("book-parts");
        0 < a.length && w(this, a[0].getElementsByTagName("a"));
        a = document.getElementById("next_previous");
        null !== a && (a = a.querySelectorAll('a:not([rel="external"])'), w(this, a));
        this.Z = document.getElementsByTagName("article")[0].innerHTML;
        this.$ = document.getElementsByTagName("title")[0].innerHTML
    },
    ca: function () {
        var a = null,
            b = document.querySelectorAll(".svg-container");
        Array.prototype.forEach.call(b, function (b) {
            b = b.querySelector(".svg-animation");
            var e = new aa(b);
            e.g();
            b.contentDocument.querySelector("svg").addEventListener("click", function () {
                a && e !== a && a.ba() && a.stop();
                e.ba() || (e.start(), a = e)
            })
        });
        void 0 !== iphone && iphone.M();
        Array.prototype.forEach.call(document.getElementsByTagName("video"), function (a) {
            new x(a)
        })
    },
    pa: function (a) {
        if (!a.metaKey && !a.ctrlKey) {
            a.preventDefault();
            var b = window.location.origin + window.location.pathname,
                c = a.target.origin + a.target.pathname;
            a.target.href === window.location.href ? (b = a.target.hash, "" === b && (b = "#" + a.target.getAttribute("data-id")),
            b = document.getElementsByName(b.substring(1, b.length)), b[0].scrollIntoView()) : c === b ? ("" !== a.target.hash ? b = document.getElementsByName(a.target.hash.substring(1, a.target.hash.length)) : (b = "#" + a.target.getAttribute("data-id"), b = document.getElementsByName(b.substring(1, b.length))), b[0].scrollIntoView()) : (b = "#" + a.target.getAttribute("data-id"), y(historian, a.target, b));
            b = a.target;
            a = document.querySelector('a[data-id="' + a.target.getAttribute("data-id") + '"]');
            z(a, b)
        }
    },
    ya: function () {},
    wa: function () {},
    xa: function () {},
    va: function () {}
};

function A(a, b, c) {
    null !== b ? a.innerHTML = b.getElementsByTagName("title")[0].innerHTML : void 0 !== c && (a.innerHTML = c)
}
function B(a, b) {
    var c = document.getElementsByTagName("article")[0];
    c.innerHTML = b;
    var e = document.getElementById("next_previous").querySelectorAll('a:not([rel="external"])');
    w(a, e);
    var f = [];
    Array.prototype.forEach.call(c.getElementsByClassName("x-name"), function (a) {
        f.push(a.firstChild)
    });
    w(a, f);
    void 0 !== mini_toc && C(mini_toc);
    window.setTimeout(historian.ca, 2E3)
}

function y(a, b, c) {
    var e = new XMLHttpRequest;
    e.addEventListener("progress", a.ya, !1);
    e.addEventListener("load", a.wa, !1);
    e.addEventListener("error", a.xa, !1);
    e.addEventListener("abort", a.va, !1);
    e.onreadystatechange = function () {
        if (4 === e.readyState) {
            var f = e.responseText,
                g = document.createElement("div");
            g.innerHTML = f;
            B(a, g.getElementsByTagName("article")[0].innerHTML);
            var f = document.getElementsByTagName("article")[0],
                k = document.getElementsByTagName("title")[0];
            A(k, g, null);
            g = {};
            g.K = f.innerHTML;
            g.na = historian.k.getAttribute("data-id");
            g.za = k.innerHTML;
            g.scrollY = window.scrollY;
            g.scrollX = window.scrollX;
            f = document.getElementById("partless");
            k = document.querySelector('a[data-id="' + b.getAttribute("data-id") + '"]');
            null !== f && (k = document.querySelector('li[data-id="' + b.getAttribute("data-id") + '"]'));
            var r = null,
                l = null;
            if (null === b.getAttribute("data-id") || void 0 === b.getAttribute("data-id")) historian.j = void 0, nav_parts.close();
            null !== k && (r = k.parentNode.parentNode.parentNode, l = k.parentNode.parentNode, null !== f && (r = k, l = k.getElementsByClassName("nav-chapters")[0]));
            null === r || -1 < r.className.split(" ").indexOf("nav-part-active") || (nav_parts.close(), nav_parts.open(l), nav_parts.i = l, historian.j = document.getElementsByClassName("nav-part-active")[0]);
            g.j = void 0 !== historian.j ? historian.j.getAttribute("data-id") : null;
            historian.Y = !1;
            history.pushState(g, b.innerHTML, b.href);
            g = b.hash.substring(1, b.hash.length);
            g = document.getElementsByName(g);
            f = document.getElementsByTagName("h2")[0];
            f.scrollIntoView(!1);
            f.focus();
            void 0 !== c && (g = c.substring(1, c.length), g = document.getElementsByName(g));
            0 < g.length && g[0].scrollIntoView();
            "undefined" !== typeof PageTracker && (g = {}, document.referrer && (g.referrer = document.referrer), g.identifier = document.getElementById("identifier").content, PageTracker.logEvent("ajaxPageLoad", g))
        }
    };
    e.open("GET", b.href);
    e.send()
}
function w(a, b) {
    Array.prototype.forEach.call(b, function (b) {
        b.addEventListener("click", a.pa)
    })
}

function z(a, b) {
    if (historian.k) {
        historian.k.classList.remove("nav-chapter-active");
        historian.k.parentElement.classList.remove("nav-current-chapter");
        var c = b.parentElement.classList.contains("next-link"),
            e = b.parentElement.classList.contains("previous-link");
        (c || e) && historian.k.parentElement.classList.add("nav-visited-chapter")
    }
    null !== a && (a.classList.add("nav-chapter-active"), a.parentElement.classList.add("nav-current-chapter"), historian.k = a, historian.j = document.getElementsByClassName("nav-part-active")[0],
    D(), E(historian.j.getElementsByTagName("ul")[0]))
}
window.onpopstate = function (a) {
    if ("reference" !== document.body.id) {
        var b = a.state;
        a = document.getElementsByTagName("title")[0];
        if (b) null !== b.K && B(historian, b.K), A(a, null, b.title), historian.k && (historian.k.classList.remove("nav-chapter-active"), historian.k.parentElement.classList.remove("nav-current-chapter")), a = document.querySelector('a[data-id="' + b.na + '"]'), a.classList.add("nav-chapter-active"), a.parentElement.classList.add("nav-current-chapter"), historian.k = a, null !== b.j ? part_chapters = document.querySelector('li[data-id="' + b.j + '"]').children[0] : (nav_parts.close(), part_chapters = void 0), void 0 !== part_chapters && (nav_parts.close(), nav_parts.open(part_chapters), nav_parts.i = part_chapters), void 0 !== b.scrollY && null !== b.scrollY && window.setTimeout(function () {
            window.scrollTo(b.scrollX, b.scrollY)
        }, 100);
        else {
            if (historian.Y) {
                historian.ca();
                var c = [];
                Array.prototype.forEach.call(document.getElementsByTagName("article")[0].getElementsByClassName("x-name"), function (a) {
                    c.push(a.firstChild)
                });
                w(historian, c)
            } else B(historian, historian.Z),
            A(a, null, historian.$);
            nav_parts.close();
            (a = document.getElementsByClassName("nav-part-active")[0]) && a.classList.remove("nav-part-active");
            if (a = document.getElementsByClassName("nav-chapter-active")[0]) a.classList.remove("nav-chapter-active"), a.parentElement.classList.remove("nav-current-chapter");
            F()
        }
    }
};
window.addEventListener("load", function () {
    "reference" !== document.body.id && (historian = new History, historian.g())
});

function G() {
    this.id = "mini_toc";
    this.element = void 0;
    this.W = 0;
    this.w = !1
}
G.prototype = {
    g: function () {
        C(this);
        return this
    },
    open: function () {
        var a = 0;
        Array.prototype.forEach.call(this.element.children, function (b) {
            a += b.clientHeight
        });
        this.element.style.height = a + 15 + "px"
    },
    close: function () {
        this.element.style.height = "25px"
    },
    e: function () {
        return -1 < (" " + this.element.className + " ").indexOf("open")
    },
    toggle: function (a) {
        a.preventDefault();
        mini_toc.e() ? (mini_toc.close(), mini_toc.element.classList.remove("open")) : (mini_toc.element.classList.add("open"), mini_toc.open())
    },
    S: function (a) {
        a.preventDefault();
        var b = document.getElementsByTagName("article")[0];
        mini_toc.close();
        mini_toc.element.classList.remove("open");
        var c = {};
        null !== history.state && (c = history.state);
        c.K = b.innerHTML;
        c.scrollY = window.scrollY;
        c.scrollX = window.scrollX;
        history.replaceState(c, b.innerHTML, window.location.href);
        a = a.target.getAttribute("href");
        var e = document.getElementsByName(a.substring(1, a.length))[0].nextSibling.nextSibling;
        e.scrollIntoView(!0);
        e.focus();
        c.scrollY = window.scrollY;
        c.scrollX = window.scrollX;
        history.pushState(c, b.innerHTML,
        a)
    },
    o: function (a) {
        var b = this;
        Array.prototype.forEach.call(a.getElementsByTagName("a"), function (a) {
            a.addEventListener("click", b.S)
        })
    }
};

function ba(a) {
    iphone || document.addEventListener("scroll", function () {
        if (!a.e()) {
            var b = window.pageYOffset;
            0 >= b ? (a.element.classList.remove("slide-out"), a.w = !1) : !a.w && b > a.W ? (a.element.classList.add("slide-out"), a.w = !0) : a.w && b < a.W && (a.element.classList.remove("slide-out"), a.w = !1);
            a.W = b
        }
    })
}

function C(a) {
    var b = document.getElementById(a.id);
    b && (a.element = b, a.o(b), document.getElementById("mini_toc_button").addEventListener("click", a.toggle), ba(a))
}
window.addEventListener("load", function () {
    mini_toc = new G;
    mini_toc.g()
});

function Navigator() {
    this.className = "part-name";
    this.i = this.ea = null
}
Navigator.prototype = {
    g: function () {
        this.ea = document.getElementsByClassName(this.className);
        "guidance" !== document.body.getAttribute("id") && this.o();
        return this
    },
    open: function (a) {
        a && "UL" === a.nodeName && (a.parentElement.classList.add("nav-part-active"), this.i = a.parentElement, D(), a.parentElement.classList.add("open-part"), "roadmap" !== document.body.id && E(a))
    },
    close: function () {
        this.i && "roadmap" !== document.body.id && (this.i.parentElement.classList.remove("open-part"), this.i.style.height = "0px");
        this.i && null !== this.i.parentElement && this.i.parentElement.classList.remove("nav-part-active")
    },
    S: function (a) {
        var b = a.target,
            c = void 0;
        if ("LI" === b.nodeName) "A" === b.firstChild.nodeName && (c = b.firstChild);
        else if ("A" === b.nodeName && !1 === b.parentElement.classList.contains("part-name")) return;
        if (void 0 !== c && !0 === b.classList.contains("nav-part-active")) z(c, c);
        else {
            var e = b.getElementsByTagName("ul")[0];
            void 0 !== e && (nav_parts.close(), nav_parts.open(e), nav_parts.i = e, (e = e.children[0].children[0]) && e.hasAttribute("href") && e.href !== window.location.href && (void 0 !== c ? z(c, c) : z(e, a.target), y(historian, e, b.getAttribute("data-id"))), void 0 !== ipad && ipad.v())
        }
    },
    o: function () {
        var a = this;
        Array.prototype.forEach.call(a.ea, function (b) {
            b.addEventListener("click", a.S)
        })
    }
};

function F() {
    var a = nav_parts,
        b = document.getElementsByTagName("article")[0].getElementsByTagName("a")[1].getAttribute("name");
    if (b = document.querySelector('a[data-id="' + b + '"]')) {
        if (b.href) {
            var c = window.location.pathname;
            b.href = c.substring(c.lastIndexOf("/") + 1, c.length) + b.hash
        }(c = b.parentElement) && "LI" === c.nodeName && (c = c.parentElement, a.open(c), a.i = c, b.classList.add("nav-chapter-active"), b.parentElement.classList.add("nav-current-chapter"), historian.k = b, historian.j = c)
    }
}

function E(a) {
    var b = 0;
    Array.prototype.forEach.call(a.children, function (a) {
        b += a.clientHeight
    });
    a.style.height = b + 15 + "px"
}
function D() {
    var a;
    historian.j && (a = historian.j.getElementsByTagName("ul")[0]);
    void 0 === a && void 0 !== nav_parts.i && (a = nav_parts.i);
    void 0 !== a && "0px" !== a.style.height && "UL" === a.nodeName && (a.style.height = "100%")
}
window.addEventListener("load", function () {
    "reference" !== document.body.id && (nav_parts = new Navigator, nav_parts.g(), F())
});

function H(a) {
    this.fa = a;
    this.b = h(a);
    this.e = !1;
    this.a = {
        filter: this.b.c(".filter"),
        h: this.b.l(".item a"),
        matches: this.b.c("#filter_matches")
    };
    this.ja = [];
    this.index = -1;
    this.matches = this.a.h.length;
    this.b.c(".JavaScript") && document.body.classList.add("js");
    ca();
    this.a.h.forEach(function (a) {
        this.ja.push(a.textContent)
    }.bind(this));
    this.r()
}
H.prototype = {
    r: function () {
        I.prototype.r.call(this);
        this.a.filter.d("focus", function () {
            this.index = -1;
            J(this);
            h("#bashful").classList.remove("slide-out");
            this.open()
        }.bind(this));
        this.b.c(".details").d("mousewheel", function (a) {
            var b = a.wheelDeltaY;
            0 < b && 0 === this.scrollTop ? a.preventDefault() : 0 > b && this.scrollTop === this.scrollHeight - this.clientHeight && a.preventDefault()
        });
        document.d("keydown", function (a) {
            if (this.e) switch (a.keyCode) {
                case 27:
                    "" === this.a.filter.value && this.close();
                    break;
                case 38:
                    a.preventDefault();
                    0 <= this.index && (this.index--, this.focus());
                    break;
                case 40:
                    a.preventDefault();
                    this.index < this.matches - 1 && (this.index++, this.focus());
                    break;
                case 13:
                    a.preventDefault(), this.b.c(".focused") && (a = this.b.c(".focused").getAttribute("href"), K(ref, a), this.close())
            }
        }.bind(this));
        this.filter()
    },
    filter: function () {
        this.a.filter.d("input", function () {
            var a = this.a.filter.value.trim().toLowerCase(),
                b, c = 0;
            this.ja.forEach(function (e) {
                if ("" === a) this.a.h[c].textContent = e, this.a.h[c].classList.remove("hidden");
                else if (/^\+( )?/.test(a)) {
                    b = RegExp("^\\+( )?" + a.substring(1), "i");
                    var f = this.a.h[c],
                        g = b;
                    g.test(e) ? L(f, g, e) : f.classList.add("hidden")
                } else /^-( )?/.test(a) ? (b = RegExp("^-( )?" + a.substring(1), "i"), f = this.a.h[c], g = b, g.test(e) ? L(f, g, e) : f.classList.add("hidden")) : 0 <= e.toLowerCase().indexOf(a) ? (b = RegExp(a, "gi"), L(this.a.h[c], b, e)) : this.a.h[c].classList.add("hidden");
                c++
            }.bind(this));
            N(this)
        }.bind(this))
    },
    open: function () {
        I.prototype.open.call(this);
        this.a.filter.focus();
        N(this)
    },
    close: function () {
        I.prototype.close.call(this);
        this.a.filter.blur();
        J(this);
        this.index = -1;
        J(this)
    },
    toggle: function () {
        I.prototype.toggle.call(this)
    },
    focus: function () {
        J(this);
        if (0 > this.index) this.a.filter.focus();
        else if (this.index < this.matches) {
            this.a.filter.blur();
            var a = O(),
                a = this.b.l(a + ".item:not(.hidden) a:not(.hidden)")[this.index];
            a.classList.add("focused");
            a.scrollIntoViewIfNeeded()
        }
    }
};

function J(a) {
    a.b.c(".focused") && a.b.c(".focused").classList.remove("focused")
}

function O() {
    return document.body.classList.contains("js") ? ".JavaScript " : document.body.classList.contains("swift") ? ".Swift " : document.body.classList.contains("obj_c") || document.body.classList.contains("both") ? ".Objective-C " : ""
}
function N(a) {
    var b = O();
    a.matches = a.b.l(b + ".item:not(.hidden) a:not(.hidden)").length;
    a.a.matches.textContent = "" === a.a.filter.value ? "" : a.matches + " match" + (1 !== a.matches ? "es" : "")
}

function L(a, b, c) {
    a.classList.remove("hidden");
    a.innerHTML = c.replace(b, '<span class="highlighted">$&</span>')
}
function ca() {
    m("#jump_to a").forEach(function (a) {
        var b = h('[name="' + a.getAttribute("href").substring(1) + '"]');
        if (b && (b = n(b, ".task-group-term"))) {
            var c = n(b, ".symbol");
            a.setAttribute("data-availability", c.dataset.availability);
            b.classList.contains("deprecated") && n(a, ".item").classList.add("deprecated")
        }
    })
};

function I(a) {
    this.fa = a;
    this.b = h(a);
    this.e = !1;
    this.r()
}
I.prototype = {
    r: function () {
        this.b.d("click", function (a) {
            n(a.target, ".details") || this.toggle()
        }.bind(this));
        document.d("click", function (a) {
            this.e && a.target !== this.b && !n(a.target, this.fa) && (a.preventDefault(), this.close())
        }.bind(this));
        this.b.d(window.la(), function () {
            this.e || (this.b.classList.remove("closing"), this.b.classList.add("closed"))
        }.bind(this))
    },
    open: function () {
        this.e || (this.b.classList.remove("closed"), this.b.classList.add("open"), this.e = !0)
    },
    close: function () {
        this.e && (this.b.classList.remove("open"),
        this.b.classList.add("closing"), this.e = !1)
    },
    toggle: function () {
        this.e ? this.close() : this.open()
    }
};

function da(a, b) {
    this.R = b;
    this.data = {};
    this.a = {
        L: h(".chapter"),
        f: {
            language: h("#language"),
            deployment_target: h("#deployment_target_" + b),
            deprecated: h("#deprecated"),
            auto_expand: h("#auto_expand")
        },
        h: m(".symbol"),
        ha: m(".task-group"),
        ta: m(".task-group-section"),
        Ea: m(".nav-parts .tasks .nav-chapter")
    };
    this.D = !1;
    this.ka = null;
    this.J = {
        V: -1 < navigator.userAgent.indexOf("Xcode/"),
        qa: -1 < navigator.userAgent.indexOf("iPad")
    }
}
da.prototype = {
    r: function () {
        this.J.qa || (ea(this), fa(this), ga(), ha());
        ia(this);
        ja(this)
    }
};

function ia(a) {
    window.d("resize", function () {
        ka()
    }.bind(a))
}
function ga() {
    h("nav.book-parts .tasks").d("mousewheel", function (a) {
        var b = a.wheelDeltaY;
        this.scrollHeight !== this.clientHeight && (0 < b && 0 === this.scrollTop ? a.preventDefault() : 0 > b && this.scrollTop === this.scrollHeight - this.clientHeight && a.preventDefault())
    })
}

function P(a, b) {
    var c = h('[name="' + b.substring(1) + '"]');
    if (c) {
        var e = n(c, ".symbol"),
            f = h("a").title,
            g = "";
        if (e) Q(a, e, !1), R(a, e).e || S(a, e), c = c.parentNode.l("a[href]"), c[0].getClientRects()[0] ? g = c[0].textContent + " - " : c[1].getClientRects()[0] && (g = c[1].textContent + " - "), document.title = g + f;
        else if (e = n(c, ".task-group")) Q(a, e, !1), g = c.parentNode.c(".section-name").textContent, document.title = g + " - " + f
    }
}

function ma() {
    var a = ref;
    h("a");
    var b = window.location.hash;
    b && (window.localStorage && "true" === localStorage.getItem("com.apple.devpubs.auto_expand") ? setTimeout(function () {
        P(this, b)
    }.bind(a), 500) : P(a, b))
}
function na() {
    var a = ref,
        b = h(".overview-bulk"),
        c = h(".overview-bulk-toggle");
    b && c.d("click", function () {
        b.classList.remove("hidden");
        b.classList.remove("squashed");
        c.parentNode.removeChild(c);
        T(this, b.clientHeight)
    }.bind(a))
}

function ha() {
    function a() {
        m(".active-task").forEach(function (a) {
            a.classList.remove("active-task")
        })
    }
    var b = h(".tasks"),
        c = m(".tasks .nav-chapter a"),
        e = [];
    c.forEach(function (a) {
        a = a.getAttribute("href").substring(1);
        a = h('a[name="' + a + '"]');
        e.push(a)
    });
    document.d("scroll", function () {
        var f = !1;
        0 >= window.pageYOffset ? (a(), b.scrollTop = 0) : window.pageYOffset >= document.height - window.innerHeight ? (a(), c[c.length - 1].classList.add("active-task"), b.scrollTop = 99999) : e.forEach(function (b) {
            if (!f) {
                var c = b.getClientRects()[0].top;
                25 >= Math.abs(c) && (a(), b = h('.tasks .nav-chapter a[href="#' + b.name + '"]'), b.classList.add("active-task"), 0 < window.pageYOffset && window.pageYOffset < document.height - window.innerHeight && b.scrollIntoViewIfNeeded(), f = !0)
            }
        })
    })
}
function fa(a) {
    document.d("keypress", function (a) {
        !a.metaKey || 102 !== a.keyCode && 103 !== a.keyCode || this.D || oa(this)
    }.bind(a))
}

function ea(a) {
    document.d("keydown", function (a) {
        if (!/(textarea|input)/i.test(document.activeElement.nodeName) && !a.metaKey) {
            if (68 === a.keyCode) return this.a.f.deprecated.checked = !this.a.f.deprecated.checked, pa(this), !1;
            if (65 === a.keyCode) return this.a.f.auto_expand.checked = !this.a.f.auto_expand.checked, qa(this), !1
        }
    }.bind(a))
}

function oa(a) {
    a.D = !0;
    var b = !1;
    h(".overview-bulk") && h(".overview-bulk").classList.remove("hidden");
    m(".symbol .height-container.hidden").forEach(function (a) {
        a.classList.remove("hidden")
    });
    ra(a);
    var c = setInterval(function () {
        var a = document.getSelection();
        if ("Range" === a.type) {
            b = !0;
            var f = a.baseNode.parentNode,
                g = n(f, ".squashed"),
                f = n(f, ".height-container");
            g ? h(".overview-bulk-toggle").click() : f && (g = n(f, ".item"), R(this, g).e || S(this, g));
            this.ka !== a.baseNode && (setTimeout(function () {
                window.scrollTo(0, window.pageYOffset + 1)
            }, 700), this.ka = a.baseNode)
        } else b && this.D && (clearInterval(c), this.D = !1, m(".symbol:not(.on) .height-container").forEach(function (a) {
            a.classList.add("hidden")
        }))
    }.bind(a), 16)
}
function ra(a) {
    var b = a.a.h.H(),
        b = sa(a) - U(a, b);
    T(a, b);
    h(".last-one").style.paddingBottom = b + "px"
}
function sa(a) {
    var b = 0;
    a.a.h.forEach(function (a) {
        a = R(this, a).p + U(this, a);
        a > b && (b = a)
    }.bind(a));
    return b
}

function ja(a) {
    m('#language input[type="radio"]').forEach(function (a) {
        a.d("change", function () {
            ta(this, a)
        }.bind(this))
    }.bind(a));
    h("#ssi_SearchField").d("focus", function () {
        this.Q.close()
    }.bind(a));
    a.a.f.deployment_target.d("change", function () {
        ua(this)
    }.bind(a));
    a.a.f.deprecated.d("change", function () {
        pa(this)
    }.bind(a));
    a.a.f.auto_expand.d("change", function () {
        qa(this)
    }.bind(a))
}

function ta(a, b) {
    var c = b.id;
    h("#language .selected") && h("#language .selected").classList.remove("selected");
    n(b, "#language").c('label[for="' + b.id + '"]').classList.add("selected");
    ["swift", "obj_c", "both"].forEach(function (a) {
        document.body.classList.remove(a)
    });
    document.body.classList.add(c);
    a.a.h.forEach(function (a) {
        var b = R(this, a);
        if (b.e) {
            var g = b.p;
            va(b);
            wa(this, a, b.p - g)
        } else b.O = !0;
        "obj_c" === c && b.G || "swift" === c && b.F ? (V(this, a), W(b)) : (!b.C || b.C && !this.a.f.deprecated.checked) && b.q <= this.a.f.deployment_target.value && b.show()
    }.bind(a));
    X(a);
    Y(a, b)
}

function xa() {
    var a = m(".instance-method .declaration .Swift .para, .class-method .declaration .Swift .para, .function .declaration .Swift .para");
    a.forEach(function (a) {
        var c = a.textContent.trim().split(/, /);
        if (1 !== c.length) {
            var e = a.innerHTML.split(/, /),
                f = 0;
            c.forEach(function (a) {
                a = a.split(c[0] !== a || /^init/.test(c[0]) ? " " : "(")[0].length;
                a > f && (f = a)
            });
            var g = 0;
            c.forEach(function (a) {
                e[g] = Array(f - (/:/.test(a) ? a.split(c[0] !== a || /^init/.test(c[0]) ? " " : "(")[0].length : -10) + 1).join("&nbsp;") + e[g];
                g++
            });
            a.innerHTML = e.join(",<br />")
        }
    });
    a = m(".instance-method .declaration .Objective-C .para, .class-method .declaration .Objective-C .para");
    a.forEach(function (a) {
        a.l(".parameter-name").forEach(function (a) {
            a.innerHTML += "<br />"
        });
        for (var c = a.l(".nl"), e = 0, e = "", f = 1; f < c.length; f++) e = a.textContent.trim().split(":")[0].length - c[f].textContent.length + 2, 0 < e && (e = Array(e).join("&nbsp;"), c[f].innerHTML = e + c[f].textContent);
        a = a.l(".n");
        for (f = 0; f < a.length; f++) /,/.test(a[f].textContent) && (e = Array(c[c.length - 1].textContent.length + 10).join("&nbsp;"), a[f].innerHTML = a[f].innerHTML.replace(/,/g, ",<br />" + e))
    })
}
function K(a, b, c) {
    c && c.metaKey ? (a = window.location, window.open(a.origin + a.pathname + b, "_blank")) : (P(a, b), history.replaceState(null, null, b))
}
function ya() {
    var a = ref;
    m(".nav-parts .tasks a, .para .x-api, .para .x-class-method, .para a.x-instance-method, #jump_to a").forEach(function (a) {
        a.d("click", function (c) {
            c.preventDefault();
            var e = a.getAttribute("href");
            K(this, e, c);
            return !1
        }.bind(this))
    }.bind(a))
}

function Y(a, b) {
    var c, e;
    switch (b.type) {
        case "radio":
            c = "language";
            e = b.id;
            break;
        case "checkbox":
            c = b.id;
            e = b.checked;
            break;
        case "select-one":
            c = b.id, e = b.value
    }
    a.J.V || !window.localStorage ? document.cookie = "com.apple.devpubs." + c + "=" + e + ";expires=" + (new Date("April 2, 2999")).toGMTString() + ";path=/" : localStorage.setItem("com.apple.devpubs." + c, e)
}

function za() {
    function a(a, b) {
        if (a && b && "false" !== b) {
            switch (a.type) {
                case void 0:
                    a = a.c("#" + b);
                    a.checked = !0;
                    break;
                case "checkbox":
                    a.checked = !0;
                    break;
                case "select-one":
                    a.value = b
            }
            var c = document.createEvent("UIEvents");
            c.initEvent("change", !1, !1);
            a.dispatchEvent(c, a)
        }
    }
    var b = ref;
    if (b.J.V || !window.localStorage) document.cookie.split(";").forEach(function (b) {
        if (b) {
            var c = b.split("=")[0].trim().replace("com.apple.devpubs.", "");
            c && (c = h("#" + c), a(c, b.split("=")[1].trim()))
        }
    });
    else for (var c in b.a.f) {
        var e = "deployment_target" === c ? "_" + b.R : "",
            f = h("#" + c + e),
            e = localStorage.getItem("com.apple.devpubs." + c + e);
        a(f, e)
    }
}
function qa(a) {
    var b;
    a.a.f.auto_expand.checked ? (b = m(".symbol:not(.on):not(.hidden)"), Aa(a, b)) : (b = m(".symbol.on"), Ba(a, b));
    Y(a, a.a.f.auto_expand)
}

function X(a) {
    function b(a, b, f, g) {
        if (0 < b) {
            var k = 1 === b ? "" : "s";
            a.textContent = b + " " + f + " symbol" + k + " hidden";
            a.title = "To show " + (1 === b ? "this" : "these") + " symbol" + k + ", change your " + g + ".";
            a.classList.remove("hidden")
        } else a.classList.add("hidden")
    }
    a.a.ha.forEach(function (a) {
        var e = 0,
            f = 0,
            g = 0,
            k = 0;
        R(this, a).h.forEach(function (a) {
            a = R(this, a);
            a.P && (a.G && document.body.classList.contains("obj_c") ? f++ : a.F && document.body.classList.contains("swift") ? e++ : a.C && this.a.f.deprecated.checked ? g++ : a.q > this.a.f.deployment_target.value && k++)
        }.bind(this));
        var r = a.c(".hiding-swift"),
            l = a.c(".hiding-obj-c"),
            q = a.c(".hiding-dep");
        a = a.c(".hiding-dt");
        r && l && q && a && (b(r, e, "Objective-C", "language setting"), b(l, f, "Swift", "language setting"), b(q, g, "deprecated", "setting in the Options menu"), b(a, k, "newer", "setting in the Options menu"))
    }.bind(a))
}

function pa(a) {
    m(".deprecated").forEach(function (a) {
        var c = n(a, ".symbol");
        c ? (V(this, c), a = R(this, c), this.a.f.deprecated.checked ? W(a) : a.G && document.body.classList.contains("obj_c") || a.F && document.body.classList.contains("swift") || a.q > this.a.f.deployment_target.value || a.show()) : a.classList.toggle("hidden")
    }.bind(a));
    X(a);
    Y(a, a.a.f.deprecated)
}

function ua(a) {
    var b = parseFloat(a.a.f.deployment_target.value, 10);
    a.Q.a.h.forEach(function (a) {
        var e = n(a, ".item");
        e.classList.contains("deprecated") || (a = parseFloat(a.dataset.q, 10), a > b ? e.classList.add("hidden") : a <= b && e.classList.remove("hidden"))
    });
    a.a.h.forEach(function (a) {
        var e = R(this, a);
        if (!e.C) if (e.q > b) V(this, a), W(e);
        else {
            (document.body.classList.contains("obj_c") && !e.G || document.body.classList.contains("swift") && !e.F || document.body.classList.contains("both")) && e.show();
            var f = a.c(".task-group-term .new");
            e.q === b ? f || (f = document.createElement("span"), f.className = "new", f.innerHTML = "(New in " + ("mac" === this.R ? "OS X" : "iOS") + " " + ("mac" === this.R ? "v10." : "") + b + ")", a.c(".task-group-term").appendChild(f)) : f && a.c(".task-group-term").removeChild(f)
        }
    }.bind(a));
    X(a);
    Y(a, a.a.f.deployment_target)
}
function U(a, b) {
    var c = R(a, b),
        e = b.offsetTop,
        f = c.y,
        g = 20;
    c.I && (g = R(a, c.I).y);
    return e + f + g + R(a, c.ia).y
}
function Q(a, b, c) {
    b = U(a, b) - 27;
    c ? Ca(a.ga, b) : window.scrollTo(0, b + 1);
    a.Q.close()
}

function wa(a, b, c) {
    var e = R(a, b).I,
        f = n(e, ".task-group-section");
    [b, e, f].forEach(function (a) {
        var b = c,
            e = a.index();
        a = a.parentNode.childNodes;
        for (var e = e + 1, f = a.length; e < f; e++) if (1 === a[e].nodeType) {
            var q = a[e],
                s = R(this, q).y || 0,
                s = s + b,
                t = q.style;
            "webkitTransform" in t ? q.style.webkitTransform = "translateY(" + s + "px)" : "mozTransform" in t ? q.style.Aa = "translateY(" + s + "px)" : "oTransform" in t ? q.style.Ca = "translateY(" + s + "px)" : "transform" in t && (q.style.transform = "translateY(" + s + "px)");
            R(this, q).y = s
        }
    }.bind(a));
    h(".last-one").classList.contains("fat") || (h(".last-one").classList.add("fat"), c += 750);
    T(a, c)
}
function S(a, b) {
    var c = R(a, b),
        e = c.p;
    c.e && (e *= -1);
    0 < e && (b.c(".height-container").classList.remove("hidden"), c.O && (va(c), e = c.p, c.O = !1));
    wa(a, b, e);
    c.toggle();
    b.classList.toggle("on")
}
function V(a, b) {
    R(a, b).e && S(a, b)
}
function Ba(a, b) {
    b.forEach(function (a) {
        V(this, a)
    }.bind(a))
}
function Aa(a, b) {
    b.forEach(function (a) {
        R(this, a).e || S(this, a)
    }.bind(a))
}

function T(a, b) {
    var c = 0;
    0 !== b && (b ? c = parseInt(a.a.L.style.height, 10) + b : (m(".hiding-symbol-counts").H().classList.add("last-one"), c = a.a.L.clientHeight), a.a.L.style.height = c + "px")
}
function ka() {
    var a = h(".nav-parts .part-name.tasks"),
        b = window.innerHeight - 70 - 32 - (h(".nav-parts").clientHeight - a.clientHeight),
        b = Math.max(b, 61);
    a.style.maxHeight = b + "px"
}

function Da() {
    var a = ref,
        b = 0;
    a.a.h.forEach(function (a) {
        var e = new Ea(a),
            f = "s" + b++;
        e.g(f);
        this.data[f] = e;
        a.l(".task-group-term a[href]").forEach(function (b) {
            b.d("click", function (f) {
                if (!f.metaKey) {
                    f.preventDefault();
                    if (!e.e) {
                        var r = a.getClientRects()[0].top;
                        f = R(this, a).p;
                        var l = window.innerHeight;
                        r + f + 30 > l && (r = U(this, a), Ca(this.ga, f + 30 < l - 97 ? r - (l - f - 30 - 70 - 10) : r - 27));
                        history.replaceState(null, null, b.href)
                    }
                    S(this, a)
                }
            }.bind(this))
        }.bind(this))
    }.bind(a));
    b = 0;
    a.a.ha.forEach(function (a) {
        var e = new Fa(a),
            f = "tg" + b++;
        e.g(f);
        this.data[f] = e;
        a.c(".section-name").d("click", function (b) {
            if (!b.metaKey) {
                b.preventDefault();
                var f = !e.e;
                f && Q(this, a, !0);
                a.l(".symbol:not(.hidden)").forEach(function (a) {
                    var b = R(this, a).e;
                    (f && !b || !f && b) && S(this, a)
                }.bind(this));
                e.toggle()
            }
        }.bind(this))
    }.bind(a));
    b = 0;
    a.a.ta.forEach(function (a) {
        var e = "c" + b++;
        a = new Z(a);
        a.g(e);
        this.data[e] = a
    }.bind(a));
    b = 0;
    m(".hiding-symbol-counts").forEach(function (a) {
        a = new Z(a);
        var e = "h" + b++;
        a.g(e);
        this.data[e] = a
    }.bind(a))
}
function R(a, b) {
    return a.data[b.id]
}
document.d("DOMContentLoaded", function () {
    if (h("#reference")) {
        var a = h("#book-title");
        a && (a.getAttribute("content"), a = h("#ios_header .header-text a").textContent.split(" ")[0].toLowerCase(), ref = new da(0, a), xa(), ref.J.V || (ref.ga = new Ga, ref.Q = new H("#jump_to"), ref.Da = new I("#options"), ka(), Da(), T(ref), ya(), ref.r(), za(), ma(), na()))
    }
});

function Ga() {
    this.ra = /(iPad|iPhone|iPod).*AppleWebKit/i.test(navigator.userAgent);
    this.X = null;
    this.B = this.s = 0;
    this.aa = !1
}
Ga.prototype = {};

function Ca(a, b) {
    var c = window.pageYOffset;
    a.s = c;
    a.B = b;
    a.aa = c < b;
    var e = Math.round((b - c) / (300 / (1E3 / 60)));
    0 !== e && function g() {
        a.X = window.requestAnimationFrame(g);
        a.s += e;
        (a.ra ? 0 : a.aa ? a.s < a.B : a.s > a.B) ? window.scrollTo(0, a.s) : (window.scrollTo(0, a.B + 1), window.cancelAnimationFrame(a.X))
    }()
};

function Z(a) {
    this.b = a;
    this.P = this.e = !1;
    this.y = 0;
    return this
}
Z.prototype = {
    g: function (a) {
        this.b.setAttribute("id", a)
    },
    show: function () {
        this.b.classList.remove("hidden");
        this.P = !1
    },
    toggle: function () {
        this.e = !this.e
    }
};

function W(a) {
    a.b.classList.add("hidden");
    a.P = !0
};

function Ea(a) {
    this.b = a;
    this.p = a.c(".section").clientHeight + 15;
    this.I = n(a, ".task-group");
    this.ia = n(this.I, ".task-group-section");
    this.C = !! this.b.c(".deprecated");
    this.G = this.b.classList.contains("swift-only");
    this.F = this.b.classList.contains("obj-c-only");
    this.q = parseFloat(a.dataset.availability, 10);
    this.O = !1;
    a.c(".height-container").classList.add("hidden");
    a.d(window.la(), function () {
        this.classList.contains("on") || this.c(".height-container").classList.add("hidden");
        h(".last-one").classList.contains("fat") && (h(".last-one").classList.remove("fat"), T(ref, -750))
    });
    return this
}
Ea.prototype = new Z;

function va(a) {
    a.p = a.b.c(".section").clientHeight + 15
};

function Fa(a) {
    this.b = a;
    this.h = a.l(".symbol");
    this.ia = n(a, ".task-group-section");
    return this
}
Fa.prototype = new Z;

function aa(a) {
    var b = {}, c, e = function () {
        return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || function (a) {
            window.setTimeout(a, 50)
        }
    }(),
        f = window.cancelAnimationFrame || window.cancelRequestAnimationFrame || window.webkitCancelAnimationFrame || window.webkitCancelRequestAnimationFrame || window.mozCancelAnimationFrame || window.mozCancelRequestAnimationFrame || window.clearTimeout,
        g, k = null,
        r = a.parentNode.querySelector(".svg-play-button"),
        l = 0,
        q = 0,
        s = 0,
        t = 0,
        M = !1;
    return {
        g: function (c) {
            b = c || {
                N: 50,
                oa: 800,
                sa: 5
            };
            k = a.contentDocument.querySelectorAll("svg > g");
            q = k.length;
            s = Math.round(b.oa / b.N);
            l = q - 1
        },
        start: function () {
            g = Date.now();
            var a = this;
            (function Ia() {
                c = e(Ia);
                a.loop()
            })();
            M = !0;
            r.classList.add("faded")
        },
        loop: function () {
            var a = Date.now(),
                c = a - g;
            c > b.N && (1 <= l && (k[l].style.display = "block", l !== q - 1 && (k[l + 1].style.display = "none")), this.next(), g = a - c % b.N)
        },
        next: function () {
            l === -1 * s ? t === b.sa - 1 ? this.stop() : (k[1].style.display = "none", l = q - 1, k[l].style.display = "block", t++) : l--
        },
        stop: function () {
            f(c);
            for (var a = 1; a < k.length; a++) k[a].style.display = "none";
            l = q - 1;
            k[l].style.display = "block";
            t = 0;
            r.classList.remove("faded");
            M = !1
        },
        ba: function () {
            return M
        }
    }
};

function x(a) {
    var b = this,
        c = a.parentNode;
    a.addEventListener("click", function (a) {
        $(b, a)
    });
    a.addEventListener("touchend", function (a) {
        $(b, a)
    });
    a.addEventListener("play", function () {
        b.play()
    });
    a.addEventListener("pause", function () {
        b.pause()
    });
    a.addEventListener("ended", function () {
        b.pause();
        b.t.element.currentTime = 0
    });
    a.addEventListener("keypress", function (a) {
        32 === a.keyCode && (a.preventDefault(), $(b, a))
    });
    b.ma = 24;
    b.t = {
        element: a
    };
    b.da = c.querySelector(".playButtonOverlay");
    return b.t.element
}
x.prototype = {
    play: function () {
        var a = this.t.element;
        this.da.classList.add("hide");
        a.play();
        a.focus()
    },
    pause: function () {
        var a = this.da;
        this.t.element.pause();
        a.classList.remove("hide")
    }
};

function $(a, b) {
    b && b.offsetY > a.t.element.videoHeight - a.ma || (a.t.element.paused ? a.play() : a.pause())
};

function Ha() {
    this.version = void 0
}
Ha.prototype = {
    g: function () {
        var a = navigator.userAgent;
        this.version = parseFloat(a.slice(a.indexOf("Xcode/") + 6, a.length));
        if (5 <= this.version) {
            var a = document.getElementsByTagName("head")[0],
                b;
            b = a.querySelector("link[rel=stylesheet]").href;
            b = b.substring(0, b.lastIndexOf("/") + 1);
            var c = document.createElement("link");
            c.setAttribute("rel", "stylesheet");
            c.setAttribute("type", "text/css");
            c.setAttribute("href", b + "xcode5.css");
            c.setAttribute("id", "xcode5");
            a.appendChild(c)
        }
    }
};
document.addEventListener("DOMContentLoaded", function () {
    -1 < navigator.userAgent.indexOf("Xcode/") ? (xcode = new Ha, xcode.g()) : xcode = void 0
});

//# sourceMappingURL=./devpubs.js.map