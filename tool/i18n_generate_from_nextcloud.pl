#!/usr/bin/perl
# A script that auto-populates a Pantry translation file based upon
# translations of the Nextcloud app. See usage instructions at the bottom of
# this file.
#
# i18n_generate_from_nextcloud.pl
# Copyright (C) Eskild Hustvedt 2026
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use v5.34;
use strict;
use English;
use open qw(:std :utf8);
use utf8;
use feature qw(signatures try);
no warnings qw(experimental::signatures experimental::try);
use YAML::PP::LibYAML;
use YAML::PP::Common qw/ :PRESERVE /;
use JSON;
use IO::All;
use IPC::Cmd qw(can_run);
use Pod::Usage;

my $autoTranslated = 0;

# Recursively called subroutine that iterates through the translation tree
sub replaceStringsRecursive( $source, $nextcloudTranslations )
{
    foreach my $key ( keys %{$source} )
    {
        if ( ref( $source->{$key} )
            && !( ref( $source->{$key} ) eq 'YAML::PP::Preserve::Scalar' ) )
        {
            replaceStringsRecursive( $source->{$key}, $nextcloudTranslations );
        }
        else
        {
            my $original = lc( $source->{$key} . '' );
            if (   $nextcloudTranslations->{$original}
                && $source->{$key} ne $nextcloudTranslations->{$original} )
            {
                $source->{$key} = $nextcloudTranslations->{$original};
                $autoTranslated++;
            }
        }
    }
}

# Output usage based on the POD at the end of this file
sub usage( $msg = undef, $exit = 0 )
{
    pod2usage(
        -exitval  => $exit,
        -message  => $msg,
        -verbose  => 99,
        -sections => 'i18n_generate_from_nextcloud.pl'
    ) if ( !@ARGV );
}

# Main entry
sub main ()
{
    usage() if ( !@ARGV );

    # The nextcloud JSON file
    my $nextcloudFile = shift(@ARGV);

    # The flutter YAML file
    my $targetFile = shift(@ARGV);

    # Validate args
    usage(
        "Error: You must specify both the path to a Nextcloud Pantry JSON-file and a Flutter Pantry YAML-file.\n",
        1
    ) if ( !defined $nextcloudFile || !defined $targetFile );
    usage( "Error: $nextcloudFile does not exist or is not readable\n", 1 )
        if ( !-e $nextcloudFile || !-r $nextcloudFile );
    usage( "Error: $targetFile does not exist or is not readable\n", 1 )
        if ( !-e $targetFile || !-r $targetFile );
    usage( "Error: $targetFile is not writeable\n", 1 )
        if ( !-w $targetFile );

    # Our YAML handler. We tell it to preserve the order of the original file
    # so that git diffs are (mostly) correct. Mostly, because it might apply
    # some wrapping.
    my $yp
        = YAML::PP::LibYAML->new(
            preserve => PRESERVE_ORDER | PRESERVE_SCALAR_STYLE | PRESERVE_FLOW_STYLE
            | PRESERVE_ALIAS );

    # Load the JSON file
    my $ncData = decode_json( scalar io($nextcloudFile)->slurp )
        or die("Failed to parse JSON file");

    # Load the YAML file
    my $yaml = $yp->load_file($targetFile) or die("Failed to load YAML file");

    # Lowercase all source keys, so that casing in the English version between
    # flutter and Nextcloud are ignored
    foreach my $src ( keys %{ $ncData->{translations} } )
    {
        my $target = $ncData->{translations}->{$src};
        delete( $ncData->{translations}->{$src} );
        $ncData->{translations}->{ lc($src) } = $target;

        # Also add an alternative version without a leading .
        if ( $src =~ s/\.$// )
        {
            $ncData->{translations}->{ lc($src) } = $target;
        }
    }

    # Perform the updates
    replaceStringsRecursive( $yaml, $ncData->{translations} );

    # autoTranslated will be nonzero if we actually made any changes
    if ($autoTranslated)
    {
        io($targetFile)->write( $yp->dump($yaml) );
        say
            "Done, wrote $targetFile. Used $autoTranslated translations from Nextcloud.";
    }
    else
    {
        say "Nothing to update.";
    }
}

main();
__END__ =pod

=head1 i18n_generate_from_nextcloud.pl

This script lets you pull in translations from the Pantry Nextcloud app into a
translation file for the Flutter app, saving you time from having to do this manually.

This script is written in perl and needs the "YAML::PP::LibYAML", "JSON" and
"IO:All" modules. You can for instance use a tool like cpanm (CPAN minus) to
install them, or get them from your Linux distro repositories if you're on Linux.

You run it like this: I<perl tool/i18n_generate_from_nextcloud.pl
/path/to/nextcloud-pantry-git/l10n/LANG.json
./lib/i18n/messages_LANG.i18n.yaml>. For instance if your language is nn, and
you have the nextcloud-pantry git repo checked out to ~/nextcloud-pantry then
the command becomes: I<perl tool/i18n_generate_from_nextcloud.pl
~/nextcloud-pantry/l10n/nn_NO.json ./lib/i18n/messages_nn.i18n.yaml>.

It will only update strings that are not translated already.
