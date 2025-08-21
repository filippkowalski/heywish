'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Heart, ArrowLeft, Plus, X, ExternalLink, Check } from 'lucide-react';
import { Label } from '@/components/ui/label';

interface WishItem {
  id: string;
  title: string;
  price: string;
  url: string;
  description: string;
}

export default function CreateWishlistPage() {
  const [wishlistTitle, setWishlistTitle] = useState('');
  const [wishlistDescription, setWishlistDescription] = useState('');
  const [items, setItems] = useState<WishItem[]>([]);
  const [currentItem, setCurrentItem] = useState<WishItem>({
    id: '',
    title: '',
    price: '',
    url: '',
    description: ''
  });
  const [isAddingItem, setIsAddingItem] = useState(false);
  const [isCreated, setIsCreated] = useState(false);
  const [shareUrl, setShareUrl] = useState('');

  const addItem = () => {
    if (!currentItem.title.trim()) return;
    
    const newItem: WishItem = {
      ...currentItem,
      id: Date.now().toString()
    };
    
    setItems([...items, newItem]);
    setCurrentItem({ id: '', title: '', price: '', url: '', description: '' });
    setIsAddingItem(false);
  };

  const removeItem = (id: string) => {
    setItems(items.filter(item => item.id !== id));
  };

  const createWishlist = async () => {
    if (!wishlistTitle.trim() || items.length === 0) return;
    
    try {
      // TODO: Implement actual wishlist creation API call
      // For now, show message that this is a demo
      setShareUrl('Demo mode - Real implementation coming soon!');
      setIsCreated(true);
    } catch (error) {
      console.error('Error creating wishlist:', error);
      // Handle error appropriately
    }
  };

  if (isCreated) {
    return (
      <div className="min-h-screen bg-background">
        {/* Navigation */}
        <nav className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
          <div className="container mx-auto px-4 py-4">
            <div className="flex items-center justify-between">
              <Link href="/" className="flex items-center space-x-2">
                <Heart className="h-8 w-8 text-primary" />
                <span className="text-2xl font-bold font-poppins">HeyWish</span>
              </Link>
              <Button variant="ghost" size="sm" asChild>
                <Link href="/app">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to App
                </Link>
              </Button>
            </div>
          </div>
        </nav>

        {/* Success Screen */}
        <section className="py-20">
          <div className="container mx-auto px-4 text-center">
            <div className="max-w-2xl mx-auto">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
                <Check className="h-10 w-10 text-green-600" />
              </div>
              
              <h1 className="text-4xl font-bold font-poppins mb-4">
                🎉 Your wishlist is ready!
              </h1>
              
              <p className="text-xl text-muted-foreground mb-8">
                <strong>{wishlistTitle}</strong> has been created with {items.length} items. 
                Share it with friends and family so they know exactly what you're hoping for.
              </p>

              <Card className="mb-8 bg-primary/5 border-primary/20">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <Label className="text-sm font-medium text-muted-foreground">Your shareable link:</Label>
                      <p className="text-sm font-mono bg-white px-3 py-2 rounded border mt-1">
                        {shareUrl}
                      </p>
                    </div>
                    <Button 
                      size="sm" 
                      onClick={() => navigator.clipboard.writeText(shareUrl)}
                    >
                      Copy Link
                    </Button>
                  </div>
                </CardContent>
              </Card>

              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Button size="lg" asChild>
                  <Link href={shareUrl.replace(window.location.origin, '')}>
                    <ExternalLink className="h-4 w-4 mr-2" />
                    View Your Wishlist
                  </Link>
                </Button>
                <Button variant="outline" size="lg" asChild>
                  <Link href="/app/create">Create Another</Link>
                </Button>
              </div>
            </div>
          </div>
        </section>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center space-x-2">
              <Heart className="h-8 w-8 text-primary" />
              <span className="text-2xl font-bold font-poppins">HeyWish</span>
            </Link>
            <Button variant="ghost" size="sm" asChild>
              <Link href="/app">
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to App
              </Link>
            </Button>
          </div>
        </div>
      </nav>

      {/* Create Wishlist Form */}
      <section className="py-8">
        <div className="container mx-auto px-4 max-w-4xl">
          <div className="mb-8">
            <h1 className="text-3xl font-bold font-poppins mb-2">Create New Wishlist</h1>
            <p className="text-muted-foreground">
              Add the items you're hoping for and share your wishlist with friends and family.
            </p>
          </div>

          <div className="grid lg:grid-cols-2 gap-8">
            {/* Wishlist Details */}
            <div>
              <Card>
                <CardHeader>
                  <CardTitle>Wishlist Details</CardTitle>
                  <CardDescription>Give your wishlist a name and description</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label htmlFor="title">Wishlist Title</Label>
                    <Input
                      id="title"
                      placeholder="My Birthday Wishlist"
                      value={wishlistTitle}
                      onChange={(e) => setWishlistTitle(e.target.value)}
                    />
                  </div>
                  <div>
                    <Label htmlFor="description">Description (optional)</Label>
                    <Textarea
                      id="description"
                      placeholder="Items I'd love for my birthday this year..."
                      value={wishlistDescription}
                      onChange={(e) => setWishlistDescription(e.target.value)}
                      rows={3}
                    />
                  </div>
                </CardContent>
              </Card>

              {/* Add Item Form */}
              <Card className="mt-6">
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    Add Items
                    <Badge variant="secondary">{items.length} items</Badge>
                  </CardTitle>
                  <CardDescription>Add the things you're hoping for</CardDescription>
                </CardHeader>
                <CardContent>
                  {!isAddingItem ? (
                    <Button onClick={() => setIsAddingItem(true)} className="w-full">
                      <Plus className="h-4 w-4 mr-2" />
                      Add Item
                    </Button>
                  ) : (
                    <div className="space-y-4">
                      <div>
                        <Label htmlFor="item-title">Item Name</Label>
                        <Input
                          id="item-title"
                          placeholder="Nike Air Max 90"
                          value={currentItem.title}
                          onChange={(e) => setCurrentItem({...currentItem, title: e.target.value})}
                        />
                      </div>
                      <div>
                        <Label htmlFor="item-price">Price (optional)</Label>
                        <Input
                          id="item-price"
                          placeholder="$120"
                          value={currentItem.price}
                          onChange={(e) => setCurrentItem({...currentItem, price: e.target.value})}
                        />
                      </div>
                      <div>
                        <Label htmlFor="item-url">Product Link (optional)</Label>
                        <Input
                          id="item-url"
                          placeholder="https://..."
                          value={currentItem.url}
                          onChange={(e) => setCurrentItem({...currentItem, url: e.target.value})}
                        />
                      </div>
                      <div>
                        <Label htmlFor="item-description">Notes (optional)</Label>
                        <Textarea
                          id="item-description"
                          placeholder="Size 9, prefer black or white..."
                          value={currentItem.description}
                          onChange={(e) => setCurrentItem({...currentItem, description: e.target.value})}
                          rows={2}
                        />
                      </div>
                      <div className="flex gap-2">
                        <Button onClick={addItem} disabled={!currentItem.title.trim()}>
                          Add Item
                        </Button>
                        <Button 
                          variant="outline" 
                          onClick={() => {
                            setIsAddingItem(false);
                            setCurrentItem({ id: '', title: '', price: '', url: '', description: '' });
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>

            {/* Items List & Preview */}
            <div>
              <Card>
                <CardHeader>
                  <CardTitle>Your Items</CardTitle>
                  <CardDescription>
                    {items.length === 0 ? "No items yet" : `${items.length} items in your wishlist`}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {items.length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                      <p>Add some items to get started!</p>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {items.map((item) => (
                        <div key={item.id} className="border rounded-lg p-3">
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <h4 className="font-medium">{item.title}</h4>
                              {item.price && (
                                <p className="text-sm text-green-600 font-medium">{item.price}</p>
                              )}
                              {item.description && (
                                <p className="text-sm text-muted-foreground mt-1">{item.description}</p>
                              )}
                              {item.url && (
                                <a 
                                  href={item.url} 
                                  target="_blank" 
                                  rel="noopener noreferrer"
                                  className="text-sm text-primary hover:underline inline-flex items-center mt-1"
                                >
                                  View Product <ExternalLink className="h-3 w-3 ml-1" />
                                </a>
                              )}
                            </div>
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => removeItem(item.id)}
                            >
                              <X className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>

              {/* Create Button */}
              <Card className="mt-6">
                <CardContent className="p-6">
                  <Button 
                    size="lg" 
                    className="w-full" 
                    onClick={createWishlist}
                    disabled={!wishlistTitle.trim() || items.length === 0}
                  >
                    Create Wishlist & Get Share Link
                  </Button>
                  <p className="text-xs text-muted-foreground text-center mt-2">
                    Your wishlist will be shareable via a unique link
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}