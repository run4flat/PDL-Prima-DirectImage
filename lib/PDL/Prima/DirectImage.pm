package PDL::Prima::DirectImage;

use strict;
use warnings;
#use Carp;
use PDL;
use Prima;

BEGIN {
	our $VERSION = '0.01_00';
	use XSLoader;
	XSLoader::load 'PDL::Prima::DirectImage', $VERSION;
}

sub Prima::Image::as_pdl :lvalue {
	my $image = shift;
	my $pdl = _as_pdl($image);
	# If the image data is aligned to 32-bit boundaries, then _as_pdl should
	# return a 3 x w x h piddle. If the image is not aligned to 32-bit
	# boundaries, we need to slice the piddle and reshape it so operations
	# only modify the drawable area
	if ($pdl->ndims != 3) {
		my $stride_offset = $image->width * 3 - 1;
		$pdl = $pdl->slice("0:$stride_offset,:")->reshape(3, $image->width,
			$image->height);
	}
	$pdl;
}

1;

__END__
# Need to make sure that Prima's padding methods are accounted for in data
# allocation via PDL so that the offset arithmetic Just Works.

# Returns a Prima Image with memory mapped up and everything
my $key = 'PDL::Prima::DirectImage/image';
sub directimage {
	my $self = shift;
	
	# Create the directimage if it doesn't already exist
	$self->hdr->{$key} = $self->wrap_directimage
		unless exists $self->hdr->{$key};
	
	# Return the already-created direct image if it exists
	return $self->hdr->{$key};
}

sub wrap_directimage {
	my $self = shift;
	
	# XXX assume RGB for now
	croak('Piddle must have dim(2) == 3; RGB only for now')
		unless $self->dim(2) == 3;
	
	# Create the new image
	my $image = Prima::Image->create(
		width => $self->dim(0),
		height => $self->dim(1),
		type => im::RGB,
	);
	
	_wrap_directimage($self, $image);
}