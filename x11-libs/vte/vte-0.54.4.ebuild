# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
VALA_USE_DEPEND="vapigen"
VALA_MIN_API_VERSION="0.32"

inherit gnome2 vala

DESCRIPTION="Library providing a virtual terminal emulator widget"
HOMEPAGE="https://wiki.gnome.org/Apps/Terminal/VTE"

LICENSE="LGPL-2+"
SLOT="2.91"
IUSE="+crypt debug glade +introspection vala vanilla"
KEYWORDS="amd64 arm ~arm64 ~mips ppc ppc64 x86"
REQUIRED_USE="vala? ( introspection )"

SRC_URI="${SRC_URI} !vanilla? ( https://dev.gentoo.org/~leio/distfiles/${PN}-0.54.1-command-notify.patch.xz )"

RDEPEND="
	>=dev-libs/glib-2.40:2
	>=dev-libs/libpcre2-10.21
	>=x11-libs/gtk+-3.16:3[introspection?]
	>=x11-libs/pango-1.22.0

	sys-libs/ncurses:0=
	sys-libs/zlib

	crypt?  ( >=net-libs/gnutls-3.2.7:0= )
	glade? ( >=dev-util/glade-3.9:3.10 )
	introspection? ( >=dev-libs/gobject-introspection-0.9.0:= )
"
DEPEND="${RDEPEND}
	dev-libs/libxml2:2
	dev-util/glib-utils
	>=dev-util/gtk-doc-am-1.13
	>=dev-util/intltool-0.35
	sys-devel/gettext
	virtual/pkgconfig

	vala? ( $(vala_depend) )
"
RDEPEND="${RDEPEND}
	!x11-libs/vte:2.90[glade]
"

src_prepare() {
	if ! use vanilla; then
		# First half of http://pkgs.fedoraproject.org/cgit/rpms/vte291.git/tree/vte291-command-notify-scroll-speed.patch
		# Adds OSC 777 support for desktop notifications in gnome-terminal or elsewhere
		eapply "${WORKDIR}"/${PN}-0.54.1-command-notify.patch
	fi

	eapply "${FILESDIR}/${PN}-0.54.2-musl-remove-W_EXITCODE.patch"

	use vala && vala_src_prepare

	# build fails because of -Werror with gcc-5.x
	sed -e 's#-Werror=format=2#-Wformat=2#' -i configure || die "sed failed"

	gnome2_src_prepare
}

src_configure() {
	local myconf=""

	if [[ ${CHOST} == *-interix* ]]; then
		myconf="${myconf} --disable-Bsymbolic"

		# interix stropts.h is empty...
		export ac_cv_header_stropts_h=no
	fi

	gnome2_src_configure \
		--disable-static \
		--with-gtk=3.0 \
		--with-iconv \
		$(use_enable debug) \
		$(use_enable glade glade-catalogue) \
		$(use_with crypt gnutls) \
		$(use_enable introspection) \
		$(use_enable vala) \
		${myconf}
}

src_install() {
	gnome2_src_install
	mv "${ED}"/etc/profile.d/vte{,-${SLOT}}.sh || die
}
