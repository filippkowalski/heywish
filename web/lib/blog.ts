import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';
import readingTime from 'reading-time';
import { remark } from 'remark';
import html from 'remark-html';

const contentDirectory = path.join(process.cwd(), 'content/blog');

// Simple in-memory cache for blog posts
let cachedPosts: BlogPostMetadata[] | null = null;
let cacheTimestamp: number = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes in milliseconds

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  date: string;
  author: {
    name: string;
    avatar?: string;
  };
  tags: string[];
  featured?: boolean;
  image?: string;
  content: string;
  readingTime: string;
}

export interface BlogPostMetadata {
  slug: string;
  title: string;
  description: string;
  date: string;
  author: {
    name: string;
    avatar?: string;
  };
  tags: string[];
  featured?: boolean;
  image?: string;
  readingTime: string;
}

export function getAllBlogPosts(): BlogPostMetadata[] {
  // Check if we have valid cached data
  const now = Date.now();
  if (cachedPosts && (now - cacheTimestamp) < CACHE_DURATION) {
    return cachedPosts;
  }

  if (!fs.existsSync(contentDirectory)) {
    return [];
  }

  const fileNames = fs.readdirSync(contentDirectory);
  
  const allPostsData = fileNames
    .filter((fileName) => fileName.endsWith('.mdx'))
    .map((fileName) => {
      const slug = fileName.replace(/\.mdx$/, '');
      const fullPath = path.join(contentDirectory, fileName);
      const fileContents = fs.readFileSync(fullPath, 'utf8');
      const { data, content } = matter(fileContents);
      const { text: readingTimeText } = readingTime(content);

      return {
        slug,
        title: data.title || 'Untitled',
        description: data.description || '',
        date: data.date || '2024-01-01',
        author: data.author || { name: 'HeyWish Team', avatar: undefined },
        tags: data.tags || [],
        featured: data.featured || false,
        image: data.image || undefined,
        readingTime: readingTimeText,
      };
    });

  const sortedPosts = allPostsData.sort((a, b) => (a.date < b.date ? 1 : -1));
  
  // Cache the results
  cachedPosts = sortedPosts;
  cacheTimestamp = now;
  
  return sortedPosts;
}

export async function getBlogPost(slug: string): Promise<BlogPost | null> {
  if (!fs.existsSync(contentDirectory)) {
    return null;
  }

  try {
    const fullPath = path.join(contentDirectory, `${slug}.mdx`);
    const fileContents = fs.readFileSync(fullPath, 'utf8');
    const { data, content } = matter(fileContents);
    const { text: readingTimeText } = readingTime(content);

    // Process markdown content to HTML
    const processedContent = await remark()
      .use(html)
      .process(content);
    const contentHtml = processedContent.toString();

    return {
      slug,
      title: data.title || 'Untitled',
      description: data.description || '',
      date: data.date || '2024-01-01',
      author: data.author || { name: 'HeyWish Team' },
      tags: data.tags || [],
      featured: data.featured || false,
      image: data.image || null,
      content: contentHtml,
      readingTime: readingTimeText,
    };
  } catch (error) {
    return null;
  }
}

export function getFeaturedBlogPosts(limit: number = 3): BlogPostMetadata[] {
  const allPosts = getAllBlogPosts();
  return allPosts.filter(post => post.featured).slice(0, limit);
}

export function getBlogPostsByTag(tag: string): BlogPostMetadata[] {
  const allPosts = getAllBlogPosts();
  return allPosts.filter(post => post.tags.includes(tag));
}

export function getAllTags(): string[] {
  const allPosts = getAllBlogPosts();
  const tags = new Set<string>();
  
  allPosts.forEach(post => {
    post.tags.forEach(tag => tags.add(tag));
  });
  
  return Array.from(tags).sort();
}