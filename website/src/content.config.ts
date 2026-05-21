import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const staticPages = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/content/static" }),
  schema: z.object({ title: z.string(), description: z.string(), effectiveDate: z.string().optional() }),
});

export const collections = { static: staticPages };
