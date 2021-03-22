#!/d/perl/bin/perl.exe -w
# Generate flash card web page.
# Requires 'template.html' and '[language]_phrases.txt'.
# Optional files are '[language]_colours.txt' and '[language]_language.txt'.
# Has only been used for German and Sanskrit so far.

# There are four lines of code which need to be uncommented to support the
# Devanagari typeface for Sanskrit. Two of them are here, and the other two
# use the Sanskrit library to set language transformations.
# TO DO: should ONLY access this module if language is set to Sanskrit;
# but this is much simpler than determining this at run time (I think ...)
#use lib "../Sanskrit"; # hmmm, assumes a certain folder
#use Sanskrit;

sub js_array_literal(@);
sub js_array_literal_strs(@);

my $lang_ph = qr/\%\%lang\%\%/; # placeholder for languages (first line)
my $phrase_ph = qr/\%\%phrase\%\%/; # placeholder for phrases (rest of file)
my $colour_ph = qr/\%\%colour\%\%/; # placeholder for colours
my $left_font_ph = qr/\%\%left-font\%\%/;
my $right_font_ph = qr/\%\%right-font\%\%/;

@ARGV == 1 or die "Required parameter 'language_filename_base' missing!\n";

my $phrase_src = $ARGV[0] . "_phrases.txt"; # Required.
my $template_src = "template.html"; # Required; fixed file name.
my $colour_src = $ARGV[0] . "_colours.txt"; # Optional.
my $lang_src = $ARGV[0] . "_language.txt"; # Optional.

# Set up default (identity) character set transformations.
my $left_lang_transform = sub { return shift; };
my $right_lang_transform = sub { return shift; };

# Set up default (boring) fonts.
my $left_font = "serif";
my $right_font = "serif";

# Determine language (font) mapping definition (optional).
if(-e $lang_src) {
	open(LANG, $lang_src) or die "Unable to open $lang_src";
	my @lang_ctl = <LANG>;
	close(LANG);
	my ($left_lang, $right_lang) = split(/=/, $lang_ctl[0]);
	($left_font, $right_font) = split(/=/, $lang_ctl[1]);
	chomp($left_lang, $right_lang, $left_font, $right_font);
	#$left_lang_transform = \&Sanskrit::devanagari if $left_lang eq 'Sanskrit';
	#$right_lang_transform = \&Sanskrit::devanagari if $right_lang eq 'Sanskrit';
}

# Build phrase tables.
open(PHR, $phrase_src) or die "Unable to open $phrase_src";
my $first_line = 1;
my $lang = "";
my @phrase = ();
foreach(<PHR>) {
	chomp;
	next if /^$/;
	my @word = split(/=/);
	$lang = js_array_literal_strs($word[0], $word[1]) if $first_line;
	push @phrase, js_array_literal_strs(&$left_lang_transform($word[0]), 
					&$right_lang_transform($word[1]))
		if !$first_line;
	$first_line = 0;
}
close(PHR);

# Build colour table (optional).
my @colour = ();
if(-e $colour_src) {
	open(COL, $colour_src) or die "Unable to open $colour_src";
	foreach(<COL>) {
	chomp;
	my @mapping = split(/=/);
	push @colour, js_array_literal_strs($mapping[0], $mapping[1]);
	}
	close(COL);
}

# Substitute into template.
open(TPL, $template_src) or die "Unable to open $template_src";
foreach(<TPL>) {
	my $line = $_;
	$line =~ s/$lang_ph/$lang/ if /$lang_ph/;
	$line =~ s/$phrase_ph/js_array_literal(@phrase)/e if /$phrase_ph/;
	$line =~ s/$colour_ph/js_array_literal(@colour)/e if /$colour_ph/;
	$line =~ s/$left_font_ph/$left_font/ if /$left_font_ph/;
	$line =~ s/$right_font_ph/$right_font/ if /$right_font_ph/;
	print "$line";
}
close(TPL);

# Returns a JavaScript array literal representation of the list of objects
# without doing anything to them.  Line breaks are inserted.
sub js_array_literal(@) {
	"[" . join(",\n", @_) . "]";
}

# Returns a JavaScript array literal representation of the list of strings.
sub js_array_literal_strs(@) {
	s/\'/\\'/g foreach(@_);
	js_array_literal(map("'" . $_ . "'", @_));
}
