#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

//////////////////////// PDL Stuff ////////////////////////
#include "pdl.h"
#include "pdlcore.h"

static Core* PDL;
static SV* CoreSV;

//////////////////////// Prima Stuff ////////////////////////

#undef WORD
#include <apricot.h>

#include <generic/Image.h>
#undef  my

// Use this to call methods, i.e. my->begin_paint(image);
#define my  ((( PImage) image)-> self)

// Use this to access object data, i.e. var->data
#define var (( PImage) image)

// Needed for kindof check
PImage_vmt CImage;

static void default_magic (pdl *p, size_t pa) {
	/* Handle the reference counting by hand, thus allowing Perl to handle
	 * the SV cleanup; zero the piddle's pointer so it doesn't touch the
	 * SV late in the piddle's cleanup stage. */
	SvREFCNT_dec((SV*)(p->datasv));
	p->datasv = 0;
	p->data = 0;
}

// Need to make sure that Prima's padding methods are accounted for in data
// allocation via PDL so that the offset arithmetic Just Works.

MODULE = PDL::Prima::DirectImage           PACKAGE = PDL::Prima::DirectImage

#void _update_data(imagesv)
#		SV * imagesv;
#	PREINIT:
#		Handle image;
#	CODE:
#		if (!(image = gimme_the_mate(imagesv))) croak("bad object");
#		my->update_change(image);

pdl * _as_pdl(imagesv)
		SV * imagesv;
	PREINIT:
		Handle image;
		PDL_Indx w, h, stride;
		pdl * npdl;
	CODE:
		/* Make sure we have an image we can work with */
		if ( !(image = gimme_the_mate(imagesv)) || !kind_of(image, CImage)
			|| var->type != imbpp24
		) {
			croak("bad object");
		}
		
		/* Increment this image's refcount; it'll be decremented by the
		 * delete magic. */
		SvREFCNT_inc(imagesv);
		
		/* Get the dimensions */
		w      = var->w;
		h      = var->h;
		stride = var->lineSize;
		
		/* Build an empty container */
		npdl = PDL->pdlnew();
		
		/* if the line has no padding, then set all three dimensions for
		 * the piddle (24-bit, width, height) */
		if (w * 3 == stride) {
			PDL_Indx dims[3] = {3, w, h};
			PDL->setdims(npdl, dims, 3);
		}
		else {
			PDL_Indx dims[2] = {stride, h};
			PDL->setdims(npdl, dims, 2);
		}
		
		/* Mark the data as foreign Bytes */
		npdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
		npdl->datatype = PDL_B;
		npdl->data = var->data;
		npdl->datasv = (void*)imagesv;
		
		
		/* Add delete_data magic */
		PDL->add_deletedata_magic(npdl, default_magic, 0);
		
		RETVAL = npdl;
	OUTPUT:
		RETVAL

#void
#set_image_to_deck_offset(piddle, image, deck_offset)
#		PDL * piddle
#		Handle image
#		int deck_offset
#	CODE:
#		var->data = piddle->data + var->dataSize * deck_offset;
#
#void _wrap_directimage(piddle, image)
#		PDL * piddle
#		Handle image
#	CODE:
#		printf("image's size is %d\n", var->dataSize);
#		free(var->data);
#		var->data = piddle->data;


BOOT:
{
	PRIMA_VERSION_BOOTCHECK;
	CImage = (PImage_vmt)gimme_the_vmt( "Prima::Image");
	
	/* PDL check stuff */
	perl_require_pv("PDL::Core");
	CoreSV = perl_get_sv("PDL::SHARE",FALSE);
	#ifndef aTHX_
	#define aTHX_
	#endif
	if (CoreSV==NULL)
		Perl_croak(aTHX_ "Can't load PDL::Core module");
	PDL = INT2PTR(Core*, SvIV( CoreSV ));
	if (PDL->Version != PDL_CORE_VERSION)
		Perl_croak(aTHX_ "[PDL->Version: %d PDL_CORE_VERSION: %d XS_VERSION: %s] PDL::Prima::DirectImage needs to be recompiled against the newly installed PDL", PDL->Version, PDL_CORE_VERSION, XS_VERSION);
}