#!/usr/bin/perl -w
use strict;
use warnings;
use DDP;
use AnyEvent::HTTP;
use AnyEvent;
use HTML::LinkExtractor;
use v5.10;
my @urls = qw(
	http://www.coffeehouse.ru);
my $count = 1;
my $cv = AnyEvent->condvar;
my @size_urls;

my $max = 4;
my $guard;
$guard = http_get $urls[0], sub {
	my ($html) = @_; 
	push @size_urls, {url => $urls[0], size => length $html};
	@urls = (@urls, parser($html, @urls)) if $#urls < 10000;
	for (1 .. $max) {
	   send_url();
	}	
};

$cv->recv;
print_info (@size_urls);


sub print_info{
	my @size_urls = @_;
	my $num = 0;
	my $all_size = 0;
	@size_urls = reverse sort { $a->{size} <=> $b->{size} } @size_urls;
	say "top of pages by size";
	while ($num < 10) {
		p $size_urls[$num];
		$num++;
	}	
	for my $page (@size_urls){
		$all_size += $page->{size};
	}
	say "ALL SIZE is $all_size";
}

sub send_url {
	return if $#size_urls >= 10000;
	my $url = $urls[$count];
	return unless defined $url;
	$count++;
	say "Start ($count) $url";
	$cv->begin;
	http_get $url, sub {
		my ($html) = @_;
		say "In work $url";
		push @size_urls, {url => $url, size => length $html};
		@urls = (@urls, parser($html, @urls)) if $#urls < 10000;
		$cv->end;
		send_url();
	};
	return 1;
}

sub parser {
	my $html = shift; 
    my @urls = @_;
    my $url = $urls[0];
	my $LX = new HTML::LinkExtractor();
    $LX->parse(\$html);
    my $links = $LX->links;
    return undef unless defined $links->[0];
    my @array = @$links;
    my @result;
    for my $link (@array){
    	if ( defined $link->{href} and $link->{tag} eq 'a' ){    		
    		if ($link->{href} =~ m[^$url.+] and $link->{href} =~ m[^(?!.*(mp3|gif|jpg|pdf|doc)).*$]){  
	    		unless ( $link->{href} ~~ @urls )   {
	       	 		push @result, $link->{href};
	       		}    				
    		}
    		elsif ($link->{href} =~ m[^/.+] and $link->{href} =~ m[^(?!.*(www|http|jpg|pdf|doc)).*$]){			
    			$link->{href} =~ s[^/(.*)][$url/$1];
    			unless ( $link->{href} ~~ @urls )   {
	       	 		push @result, $link->{href};
	       		}  
    		}
    	}
    }
    my %hash;
    @result = grep{!$hash{$_}++} @result;
   	return @result;
} 
