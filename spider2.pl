#!/usr/bin/perl -w
use strict;
use warnings;
use DDP;
use AnyEvent::HTTP;
use AnyEvent;
use v5.10;
#change to parse first page
#	http://pandok.ru/zakazat-banket
#	http://pandok.ru/sezonnoe-menyu
#	http://pandok.ru/sezonnoe-menyu/product/221-salat-letnij
#);
my @urls = qw(
	http://pandok.ru/);
my $count = 0;
my $cv = AnyEvent->condvar;
my @size_urls;

my $max = 4;
my $guard;
$guard = http_get $urls[0], sub {
		my ($html) = @_;
		 
		p @urls;
		say "$urls[0] $count received, Size: ", length $html;
		push @size_urls, {url => $urls[0], size => length $html};
		@urls = (@urls, get_data($html, $urls[0], @urls)) if $#urls < 10000;
		p @urls;
		#undef $guard;
		$count+=1;
		for (1 .. $max) {
		   send_url();
		}
		
	};



$cv->recv;
 
 
sub send_url {
	return if $#size_urls >= 10000;
	my $url = $urls[$count];
	return unless defined $url;
	$count++;
	say "Start ($count) $url";
	$cv->begin;
	http_get $url, sub {
		my ($html) = @_;
		say "$url received, Size: ", length $html;
		push @size_urls, {url => $url, size => length $html};
		@urls = (@urls, get_data($html, $url, @urls)) if $#urls < 10000;
		$cv->end;
		send_url();
	};
	return 1;
}
# normal parser
sub get_data{
    my $body = shift;
    my $url = shift;
    my @urls = @_;
    my @array;
    $body =~ s[<head>(.*)</head>][]s;
    while($body =~ s[href="($url[^"]*|/[^"]*)"][]s){
       my $str = $1;
       $str =~ s[^/(.*)][http://pandok.ru/$1];      
       unless ( $str ~~ @urls )   {
       	  push @array,$str unless $str =~ /search/;
       }  
    }
    my %hash;
    @array=grep{!$hash{$_}++} @array;
    return @array;
}